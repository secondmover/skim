// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSUserDefaults-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSUserDefaults-OAExtensions.m,v 1.11 2004/02/10 04:07:35 kc Exp $")

@implementation NSUserDefaults (OAExtensions)

- (NSColor *)colorForKey:(NSString *)defaultName;
{
    NSString *value;
    float r = 0.0, g = 0.0, b = 0.0, a = 1.0;

    value = [self stringForKey:defaultName];
    if ([value length] > 1) {
        sscanf([value cString], "%f%f%f%f", &r, &g, &b, &a);
        return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    } else
        return nil;
}

- (NSColor *)grayForKey:(NSString *)defaultName;
{
    return [NSColor colorWithCalibratedWhite:[self floatForKey:defaultName] alpha:1.0];
}

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;
{
    NSString *value;
    float r, g, b, a;
    
    if (!color) {
        [self setObject:@"" forKey:defaultName];
        return;
    }

    [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
    if (a == 1.0)
	value = [NSString stringWithFormat:@"%g %g %g", r, g, b];
    else
	value = [NSString stringWithFormat:@"%g %g %g %g", r, g, b, a];
    [self setObject:value forKey:defaultName];
}

- (void)setGray:(NSColor *)gray forKey:(NSString *)defaultName;
{
    float grayFloat;

    [[gray colorUsingColorSpaceName:NSCalibratedWhiteColorSpace] getWhite:&grayFloat alpha:NULL];
    [self setFloat:grayFloat forKey:defaultName];
}

@end


@implementation OFPreference (OAExtensions)

- (NSColor *)colorValue;
{
#warning TODO - [wiml nov2003] factor out this thrice-repeated code
    NSString *value;
    float r = 0.0, g = 0.0, b = 0.0, a = 1.0;

    value = [self stringValue];
    if ([value length] > 1) {
        sscanf([value cString], "%f%f%f%f", &r, &g, &b, &a);
        return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    } else
        return nil;
}

- (void)setColorValue:(NSColor *)color;
{
    NSString *value;
    float r, g, b, a;

    if (color == nil) {
        [self setObjectValue:nil];
        return;
    }

    [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
    if (a == 1.0)
        value = [NSString stringWithFormat:@"%g %g %g", r, g, b];
    else
        value = [NSString stringWithFormat:@"%g %g %g %g", r, g, b, a];
    [self setStringValue:value];
}

@end

@implementation OFPreferenceWrapper (OAExtensions)

- (NSColor *)colorForKey:(NSString *)defaultName;
{
    NSString *value;
    float r = 0.0, g = 0.0, b = 0.0, a = 1.0;

    value = [self stringForKey:defaultName];
    if ([value length] <= 1)
        return nil;
        
    sscanf([value cString], "%f%f%f%f", &r, &g, &b, &a);
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

- (NSColor *)grayForKey:(NSString *)defaultName;
{
    return [NSColor colorWithCalibratedWhite:[self floatForKey:defaultName] alpha:1.0];
}

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;
{
    NSString *value;
    float r, g, b, a;

    if (!color) {
        [self setObject:@"x" forKey:defaultName];
        return;
    }

    [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
    if (a == 1.0)
	value = [NSString stringWithFormat:@"%g %g %g", r, g, b];
    else
	value = [NSString stringWithFormat:@"%g %g %g %g", r, g, b, a];
    [self setObject:value forKey:defaultName];
}

- (void)setGray:(NSColor *)gray forKey:(NSString *)defaultName;
{
    float grayFloat;

    [[gray colorUsingColorSpaceName:NSCalibratedWhiteColorSpace] getWhite:&grayFloat alpha:NULL];
    [self setFloat:grayFloat forKey:defaultName];
}

@end

