// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSArray-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFMultiValueDictionary.h>
#import <OmniFoundation/OFRandom.h>
#import <OmniFoundation/NSString-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSArray-OFExtensions.m,v 1.34 2004/02/10 04:07:45 kc Exp $")

@implementation NSArray (OFExtensions)

- (id)anyObject;
{
    return [self count] > 0 ? [self objectAtIndex:0] : nil;
}

- (NSArray *)elementsAsInstancesOfClass:(Class)aClass withContext:context;
{
    NSMutableArray *array;
    NSAutoreleasePool *pool;
    NSEnumerator *elementEnum;
    NSDictionary *element;

    // keep this out of the pool since we're returning it
    array = [NSMutableArray array];

    pool = [[NSAutoreleasePool alloc] init];
    elementEnum = [self objectEnumerator];
    while ((element = [elementEnum nextObject])) {
	id instance;

	instance = [[aClass alloc] initWithDictionary:element context:context];
	[array addObject:instance];

    }
    [pool release];

    return array;
}

- (id)randomObject;
{
    unsigned int count;

    count = [self count];
    if (!count)
	return nil;
    return [self objectAtIndex:OFRandomNext() % count];
}

- (int)indexOfString:(NSString *)aString;
{
    return [self indexOfString:aString options:0 range:NSMakeRange(0, [aString length])];
}

- (int)indexOfString:(NSString *)aString options:(unsigned)someOptions;
{
    return [self indexOfString:aString options:someOptions range:NSMakeRange(0, [aString length])];
}

- (int)indexOfString:(NSString *)aString options:(unsigned)someOptions range:(NSRange)aRange;
{
    NSObject *anObject;
    Class stringClass;
    unsigned int index;
    unsigned int objectCount;
    
    stringClass = [NSString class];
    objectCount = [self count];
    for (index = 0; index < objectCount; index++) {
	anObject = [self objectAtIndex:index];
	if ([anObject isKindOfClass:stringClass] && [aString compare:(NSString *)anObject options:someOptions range:aRange] == NSOrderedSame)
	    return index;
    }
    
    return NSNotFound;
}

- (NSString *)componentsJoinedByComma;
{
    return [self componentsJoinedByString:@", "];
}

- (NSString *)componentsJoinedByCommaAndAnd;
{
    unsigned int count;
    
    count = [self count];
    if (count == 0)
        return @"";
    else if (count == 1)
        return [self objectAtIndex:0];
    else if (count == 2)
        return [NSString stringWithFormat:@"%@ and %@", [self objectAtIndex:0], [self objectAtIndex:1]];
    else {
        NSArray *headObjects;
        id lastObject;
        
        headObjects = [self subarrayWithRange:NSMakeRange(0, count - 1)];
        lastObject = [self lastObject];
        return [[[headObjects componentsJoinedByComma] stringByAppendingString:@", and "] stringByAppendingString:lastObject];
    }
}

- (unsigned)indexOfObject: (id) anObject inArraySortedUsingSelector: (SEL) selector;
{
    unsigned int low = 0;
    unsigned int range = 1;
    unsigned int test = 0;
    unsigned int count = [self count];
    NSComparisonResult result;
    id compareWith;
    IMP removedImpOfSel = [anObject methodForSelector:selector];
    IMP objectAtIndexImp = [self methodForSelector:@selector(objectAtIndex:)];
    
    while (count >= range) /* range is the lowest power of 2 > count */
        range <<= 1;

    while (range) {
        test = low + (range >>= 1);
        if (test >= count)
            continue;
	compareWith = objectAtIndexImp(self, @selector(objectAtIndex:), test);
	if (compareWith == anObject) {
            return test;
	}
	result = (NSComparisonResult)removedImpOfSel(anObject, selector, compareWith);
	if (result == NSOrderedDescending)
            low = test+1;
	else if (result == NSOrderedSame) {
	    /* uh oh - now we can't be sure of finding it by binary splitting */
	    /* fall back on something disgustingly linear (but easy) */
	    int sameAt = test;

	    while (test--) {
		compareWith = objectAtIndexImp(self, @selector(objectAtIndex:), test);
		if (compareWith == anObject) {
                    return test;
		}
		result = (NSComparisonResult)removedImpOfSel(anObject, selector,
								 compareWith);
		if (result != NSOrderedSame)
		    break;
	    }
	    test = sameAt;
	    while (++test < count) {
		compareWith = objectAtIndexImp(self, @selector(objectAtIndex:), test);
		if (compareWith == anObject) {
                    return test;
		}
	    }
	}
    }
    
    return NSNotFound;
}

static int _compareWithSelector(id obj1, id obj2, void *context)
{
    return (int)objc_msgSend(obj1, (SEL)context, obj2);
}

- (BOOL) isSortedUsingSelector:(SEL)selector;
{
    return [self isSortedUsingFunction:_compareWithSelector context:selector];
}

- (BOOL) isSortedUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;
{
    unsigned int index, count;

    count = [self count];
    if (count < 2)
        return YES;

    id obj1, obj2;
    obj2 = [self objectAtIndex: 0];
    for (index = 1; index < count; index++) {
        obj1 = obj2;
        obj2 = [self objectAtIndex: index];
        if (comparator(obj1, obj2, context) < 0)
            return NO;
    }

    return YES;
}

- (void)makeObjectsPerformSelector:(SEL)selector withObject:(id)arg1 withObject:(id)arg2;
{
    unsigned int objectIndex, objectCount;
    objectCount = CFArrayGetCount((CFArrayRef)self);
    for (objectIndex = 0; objectIndex < objectCount; objectIndex++) {
        id object = (id)CFArrayGetValueAtIndex((CFArrayRef)self, objectIndex);
        objc_msgSend(object, selector, arg1, arg2);
    }
}

- (NSDecimalNumber *)decimalNumberSumForSelector:(SEL)aSelector;
{
    NSDecimalNumber *result;
    int index;

    result = [NSDecimalNumber zero];
    index = [self count];

    while (index--) {
        NSDecimalNumber *value;

        value = objc_msgSend([self objectAtIndex:index], aSelector);
        if (value)
            result = [result decimalNumberByAdding:value];
    }
    return result;
}

- (NSArray *)numberedArrayDescribedBySelector:(SEL)aSelector;
{
    NSArray *result;
    unsigned int arrayIndex, arrayCount;

    result = [NSArray array];
    for (arrayIndex = 0, arrayCount = [self count]; arrayIndex < arrayCount; arrayIndex++) {
        NSString *valueDescription;
        id value;

        value = [self objectAtIndex:arrayIndex];
        valueDescription = objc_msgSend(value, aSelector);
        result = [result arrayByAddingObject:[NSString stringWithFormat:@"%d. %@", arrayIndex, valueDescription]];
    }

    return result;
}

- (NSArray *)objectsDescribedByIndexesString:(NSString *)indexesString;
{
    NSArray *indexes;
    NSArray *results;
    unsigned int objectIndex, objectCount;

    indexes = [indexesString componentsSeparatedByString:@" "];
    results = [NSArray array];
    for (objectIndex = 0, objectCount = [indexes count]; objectIndex < objectCount; objectIndex++) {
        NSString *index;

        index = [indexes objectAtIndex:objectIndex];
        results = [results arrayByAddingObject:[self objectAtIndex:[index unsignedIntValue]]];
    }

    return results;
}

- (NSArray *)arrayByRemovingObject:(id)anObject;
{
    NSMutableArray *filteredArray;
    
    if (![self containsObject:anObject])
        return [NSArray arrayWithArray:self];

    filteredArray = [NSMutableArray arrayWithArray:self];
    [filteredArray removeObject:anObject];

    return [NSArray arrayWithArray:filteredArray];
}

- (NSArray *)arrayByRemovingObjectIdenticalTo:(id)anObject;
{
    NSMutableArray *filteredArray;
    
    if (![self containsObject:anObject])
        return [NSArray arrayWithArray:self];

    filteredArray = [NSMutableArray arrayWithArray:self];
    [filteredArray removeObjectIdenticalTo:anObject];

    return [NSArray arrayWithArray:filteredArray];
}

- (OFMultiValueDictionary *)groupBySelector:(SEL)aSelector;
{
    int index, count;
    id currentObject;
    OFMultiValueDictionary *dictionary;

    dictionary = [[[OFMultiValueDictionary alloc] init] autorelease];
    count = [self count];

    for (index = 0; index < count; index++) {
        currentObject = [self objectAtIndex:index];
        [dictionary addObject:currentObject forKey:[currentObject performSelector:aSelector]];
    }
    return dictionary;
}

- (OFMultiValueDictionary *)groupBySelector:(SEL)aSelector withObject:(id)anObject;
{
    int index, count;
    id currentObject;
    OFMultiValueDictionary *dictionary;

    dictionary = [[[OFMultiValueDictionary alloc] init] autorelease];
    count = [self count];

    for (index = 0; index < count; index++) {
        currentObject = [self objectAtIndex:index];
        [dictionary addObject:currentObject forKey:[currentObject performSelector:aSelector withObject:anObject]];
    }
    return dictionary;
}

- (NSDictionary *)indexBySelector:(SEL)aSelector;
{
    int index, count;
    NSMutableDictionary *dictionary;

    dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    count = [self count];

    for (index = 0; index < count; index++) {
        NSString *key;
        id object;

        object = [self objectAtIndex:index];
        if ((key = [object performSelector:aSelector]))
            [dictionary setObject:object forKey:key];
    }

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSArray *)arrayByPerformingSelector:(SEL)aSelector;
{
    // objc_msgSend won't bother passing the nil argument to the method implementation because of the selector signature.
    return [self arrayByPerformingSelector:aSelector withObject:nil];
}

- (NSArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)anObject;
{
    NSMutableArray *result;
    unsigned int index, count;

    result = [NSMutableArray array];
    for (index = 0, count = [self count]; index < count; index++) {
        id singleObject;
        id selectorResult;

        singleObject = [self objectAtIndex:index];
        selectorResult = [singleObject performSelector:aSelector withObject:anObject];

        if (selectorResult)
            [result addObject:selectorResult];
    }

    return result;
}

- (NSArray *)objectsSatisfyingCondition:(SEL)aSelector;
{
    // objc_msgSend won't bother passing the nil argument to the method implementation because of the selector signature.
    return [self objectsSatisfyingCondition:aSelector withObject:nil];
}

- (NSArray *)objectsSatisfyingCondition:(SEL)aSelector withObject:(id)anObject;
{
    NSMutableArray *result;
    unsigned int index, count;

    result = [NSMutableArray array];
    for (index = 0, count = [self count]; index < count; index++) {
        id singleObject;
        BOOL selectorResult;
        Method method;
        char  (*byteImp)(id self, SEL _cmd, id arg);
        short (*shortImp)(id self, SEL _cmd, id arg);
        long  (*longImp)(id self, SEL _cmd, id arg);
        NSMethodSignature *signature;
        
        singleObject = [self objectAtIndex:index];

        signature = [singleObject methodSignatureForSelector:aSelector];
        method = class_getInstanceMethod([singleObject class], aSelector);
        switch ([signature methodReturnType][0]) {
            // TODO: change this to @encode at some point
            case 'c':
            case 'C':
                byteImp = (typeof(byteImp))method->method_imp;
                selectorResult = byteImp(singleObject, aSelector, anObject) != 0;
                break;
            case 's':
            case 'S':
                shortImp = (typeof(shortImp))method->method_imp;
                selectorResult = shortImp(singleObject, aSelector, anObject) != 0;
                break;
            case '@':
                assert(sizeof(id) == sizeof(long)); // 64-bit pointers may happen someday
            case 'i':
            case 'I':
                longImp = (typeof(longImp))method->method_imp;
                selectorResult = longImp(singleObject, aSelector, anObject) != 0;
                break;
            default:
                selectorResult = NO;
                OBASSERT(false);
                ;
        }
        
        if (selectorResult)
            [result addObject:singleObject];
    }

    return result;
}

- (NSMutableArray *)deepMutableCopy;
{
    NSMutableArray *newArray;
    unsigned int index, count;

    count = [self count];
    newArray = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:count];
    for (index = 0; index < count; index++) {
        id anObject;

        anObject = [self objectAtIndex:index];
        if ([anObject respondsToSelector:@selector(deepMutableCopy)]) {
            anObject = [anObject deepMutableCopy];
            [newArray addObject:anObject];
            [anObject release];
        } else if ([anObject respondsToSelector:@selector(mutableCopy)]) {
            anObject = [anObject mutableCopy];
            [newArray addObject:anObject];
            [anObject release];
        } else {
            [newArray addObject:anObject];
        }
    }

    return newArray;
}

- (NSArray *)reversedArray;
{
    NSMutableArray *newArray;
    unsigned int count;
    
    count = [self count];
    newArray = [[[NSMutableArray allocWithZone:[self zone]] initWithCapacity:count] autorelease];
    while (count--) {
        [newArray addObject:[self objectAtIndex:count]];
    }

    return newArray;
}

- (NSArray *)deepCopyWithReplacementFunction:(id (*)(id, void *))funct context:(void *)context;
{
    id *replacementItems = NULL;
    int itemCount, itemIndex;
    
    itemCount = [self count];
    for(itemIndex = 0; itemIndex < itemCount; itemIndex ++) {
        id item, copyItem;
        
        item = [self objectAtIndex:itemIndex];
        copyItem = (*funct)(item, context);
        if (!copyItem) {
            if ([item respondsToSelector:_cmd])
                copyItem = [item deepCopyWithReplacementFunction:funct context:context];
            else
                copyItem = [[item copy] autorelease];
        }
        if(copyItem != item && replacementItems == NULL) {
            replacementItems = NSZoneMalloc(NULL, sizeof(*replacementItems) * itemCount);
            if (itemIndex > 0)
                [self getObjects:replacementItems range:(NSRange){location:0, length:itemIndex}];
        }
        if (replacementItems != NULL)
            replacementItems[itemIndex] = copyItem;
    }
    
    if (replacementItems == NULL) {
        // TODO: If we're immutable, just return ourselves
        return [NSArray arrayWithArray:self];
    } else {
        NSArray *theCopy = [NSArray arrayWithObjects:replacementItems count:itemCount];
        NSZoneFree(NULL, replacementItems);
        return theCopy;
    }
}

// Returns YES if the two arrays contain exactly the same pointers in the same order.  That is, this doesn't use -isEqual: on the components
- (BOOL)isIdenticalToArray:(NSArray *)otherArray;
{
    unsigned int index = [self count];

    if (index != [otherArray count])
        return NO;
    while (index--)
        if ([self objectAtIndex:index] != [otherArray objectAtIndex:index])
            return NO;
    return YES;
}

// -containsObjectsInOrder: moved from TPTrending 6Dec2001 wiml
- (BOOL)containsObjectsInOrder:(NSArray *)orderedObjects
{
    unsigned myCount, objCount, myIndex, objIndex;
    id testItem = nil;
    
    myCount = [self count];
    objCount = [orderedObjects count];
    
    myIndex = objIndex = 0;
    while (objIndex < objCount) {
        id item;
        
        // Not enough objects left in self to correspond to objects left in orderedObjects
        if ((objCount - objIndex) > (myCount - myIndex))
            return NO;
        
        item = [self objectAtIndex:myIndex];
        if (!testItem)
            testItem = [orderedObjects objectAtIndex:objIndex];
        if (item == testItem) {
            testItem = nil;
            objIndex ++;
        }
        myIndex ++;
    }
    
    return YES;
}

- (BOOL)containsObjectIdenticalTo:anObject;
{
    return [self indexOfObjectIdenticalTo:anObject] != NSNotFound;
}

@end
