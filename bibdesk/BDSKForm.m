//
//  BDSKForm.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/22/05.
/*
 This software is Copyright (c) 2005
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKForm.h"
#import "BDSKComplexString.h"

#import "BibEditor.h"

// private methods for getting the rect(s) of each cell in the matrix
@interface BDSKForm (Private)
- (id)cellAtPoint:(NSPoint)point usingButton:(BOOL)usingButton;
+ (NSCursor *)fingerCursor;
- (void)setPromisedDragURL:(NSURL *)theURL;
- (void)setPromisedDragFilename:(NSString *)theFilename;
@end

@implementation BDSKForm

// this is called when loading the nib. We replace the cell class and the prototype cell
- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		dragRow = -1;
		highlight = NO;
		promisedDragFilename = nil;
		promisedDragURL = nil;
		// we replace the prototype cell with our own if necessary
		if (![[self prototype] isKindOfClass:[BDSKFormCell class]]){
			BDSKFormCell *cell = [[BDSKFormCell alloc] init];
			[cell setFont:[(NSCell *)[self prototype] font]];
			[cell setTitleFont:[[self prototype] titleFont]];
			[cell setWraps:[[self prototype] wraps]];
			[cell setScrollable:[[self prototype] isScrollable]];
			[cell setEnabled:[[self prototype] isEnabled]];
			[cell setEditable:[[self prototype] isEditable]];
			[cell setSelectable:[[self prototype] isSelectable]];
			[cell setAlignment:[[self prototype] alignment]];
			[cell setTitleAlignment:[[self prototype] titleAlignment]];
			[cell setSendsActionOnEndEditing:[[self prototype] sendsActionOnEndEditing]];
			[self setCellClass:[BDSKFormCell class]];
			[self setPrototype:cell];
			[cell release];
		}
	}
	return self;
}

-(void)drawRect:(NSRect)rect{
	[super drawRect:rect];
	if (!highlight || dragRow == -1) return;
	
	[NSGraphicsContext saveGraphicsState];
	NSSetFocusRingStyle(NSFocusRingOnly);
	NSRectFill([self cellFrameAtRow:dragRow column:0]);
	[NSGraphicsContext restoreGraphicsState];
}

- (void)dealloc{
	[promisedDragFilename release];
	[promisedDragURL release];
	[super dealloc];
}

- (void)setDelegate:(id <BDSKFormDelegate>)aDelegate{
    if(aDelegate){
        OBPRECONDITION([(id)aDelegate conformsToProtocol:@protocol(BDSKFormDelegate)]);
        NSAssert1([(id)aDelegate conformsToProtocol:@protocol(BDSKFormDelegate)], @"%@ does not conform to BDSKFormDelegate protocol", [aDelegate class]);
    }
    [super setDelegate:aDelegate];
}

- (id <BDSKFormDelegate>)delegate{
    return [super delegate];
}

- (void)mouseDown:(NSEvent *)theEvent{
    
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // NSLog(@"the point is at x = %f and y = %f", point.x, point.y);
    BDSKFormCell *cell = (BDSKFormCell *)[self cellAtPoint:mouseLoc usingButton:YES];
    if(cell){
		[cell setButtonHighlighted:YES];
		BOOL keepOn = YES;
		BOOL isInside = YES;
		while (keepOn) {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
			mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			isInside = ([self cellAtPoint:mouseLoc usingButton:YES] == cell);
			switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[cell setButtonHighlighted:isInside];
                    if(isInside && [cell hasFileIcon]){
                        NSImage *dragImage;
                        
                        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
                        NSArray *types = nil;
                        NSURL *url = nil;
						
                        url = [[self delegate] draggedURLForFormCell:cell];
						if (url == nil)
							break;
						
                        [self setPromisedDragURL:url];
                        
                        NSString *pathExtension = @"";
                        
                        if([url isFileURL]){
                            NSString *path = [url path];
                            pathExtension = [path pathExtension];
                            types = [NSArray arrayWithObjects:NSURLPboardType, NSFilesPromisePboardType, nil];
                            [pboard declareTypes:types owner:nil];
                            [url writeToPasteboard:pboard];
                            [self setPromisedDragFilename:[path lastPathComponent]];
                            [pboard setPropertyList:[NSArray arrayWithObject:promisedDragFilename] forType:NSFilesPromisePboardType];
                        } else {
							NSString *filename = nil;
                            filename = [[self delegate] draggedFileNameForFormCell:cell];
                            if ([NSString isEmptyString:filename])
								filename = @"Remote URL";
							pathExtension = @"webloc";
                            types = [NSArray arrayWithObjects:NSURLPboardType, NSFilesPromisePboardType, nil];
                            [pboard declareTypes:types owner:nil];
                            [url writeToPasteboard:pboard];
                            [self setPromisedDragFilename:[filename stringByAppendingPathExtension:@"webloc"]];
                            [pboard setPropertyList:[NSArray arrayWithObject:promisedDragFilename] forType:NSFilesPromisePboardType];
                        }
                        NSRect imageLocation;

                        mouseLoc.x -= 16;
                        mouseLoc.y -= 16;
                        imageLocation.origin = mouseLoc;
                        imageLocation.size = NSMakeSize(32,32);
                        if(![self dragPromisedFilesOfTypes:[NSArray arrayWithObject:pathExtension] fromRect:imageLocation source:self slideBack:YES event:theEvent])
                            NSLog(@"Unable to complete promised file drag.");
                        //[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:[NSApp currentEvent]];
						// we shouldn't follow the mouse events anymore
                        [cell setButtonHighlighted:NO];
						keepOn = NO;
                    }
					break;
				case NSLeftMouseUp:
					if (isInside){
                        if([cell hasArrowButton])
                            [[self delegate] arrowClickedInFormCell:cell];
                        else if([cell hasFileIcon])
                            [[self delegate] iconClickedInFormCell:cell];
                    }
					[cell setButtonHighlighted:NO];
					keepOn = NO;
					break;
				default:
					/* Ignore any other kind of event. */
					break;
			}
		}
    }else{
		[super mouseDown:theEvent];
	}
}

// Hack around the promise drag's penchant for removing all non-HFS promise types from the pasteboard, since dragPromisedFiles... calls through to this method eventually.  This allows us to drag URLs between form cells and to other apps besides the Finder.
- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation offset:(NSSize)initialOffset event:(NSEvent *)event pasteboard:(NSPasteboard *)pboard source:(id)sourceObj slideBack:(BOOL)slideFlag{
    [pboard addTypes:[NSArray arrayWithObject:NSURLPboardType] owner:nil];
    [promisedDragURL writeToPasteboard:pboard];
    [super dragImage:anImage at:viewLocation offset:initialOffset event:event pasteboard:pboard source:sourceObj slideBack:slideFlag];
}


// the AppKit calls this when necessary, so it's caching the rects for us
- (void)resetCursorRects{
    
    int rows = [self numberOfRows];
    int columns = [self numberOfColumns];
    int i, j;
	int titleWidth;
    NSRect cellRect;
    BDSKFormCell *aCell;
    
	for(i = 0; i < rows; i++){
        for(j = 0; j < columns; j++){
            // Get the cell's frame rect
            cellRect = [self cellFrameAtRow:i column:j];
            
            aCell = (BDSKFormCell *)[self cellAtRow:i column:j];
			
			// set the I-beam cursor for the text part, this takes the button into account
			[self addCursorRect:[aCell textRectForBounds:cellRect] cursor:[NSCursor IBeamCursor]];
			
			if([[self delegate] formCellHasArrowButton:aCell]){
                
                // set a finger cursor for the button part.
				[self addCursorRect:[aCell buttonRectForBounds:cellRect] cursor:[BDSKForm fingerCursor]];
            }
        }
    }
}

- (void)removeAllEntries{
    int numRows = [self numberOfRows];
    while(numRows--){
        [self removeEntryAtIndex:numRows];
    }
}

- (NSFormCell *)insertEntry:(NSString *)title
             usingTitleFont:(NSFont *)titleFont
         attributesForTitle:(NSDictionary *)attrs
                    indexAndTag:(int)index 
                objectValue:(id<NSCopying>)objectValue{
    
    // this will be an instance of the prototype cell
    NSFormCell *theCell = [self insertEntry:title atIndex:index];
    [theCell setTag:index];
    [theCell setObjectValue:objectValue];
    [theCell setTitleFont:titleFont];
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:attrs];
    [theCell setAttributedTitle:attrTitle];
    [attrTitle release];
    
    return theCell;
}

// this will only be called by the field editor on 10.3 and greater
- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index{
    // if this is a raw edit, the delegate is a MacroTextFieldWindowController, which knows about the macro resolver
    if([[self delegate] respondsToSelector:_cmd])
        return [(id)[self delegate] textView:textView completions:words forPartialWordRange:charRange indexOfSelectedItem:index];
    else
        // you probably don't want super's dictionary lookup if you're entering a macro
        return [super textView:textView completions:words forPartialWordRange:charRange indexOfSelectedItem:index];
}

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	NSPoint mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
	int row, column;
	id cell;
	
	if (![self delegate]) return NSDragOperationNone;
	
	[self getRow:&row column:&column forPoint:mouseLoc];
	cell = [self cellAtRow:row column:0];
	if (cell && (sourceDragMask & NSDragOperationCopy) &&
		[[self delegate] canReceiveDrag:sender forFormCell:cell]) {
		
		dragRow = row;
		highlight = YES;
		[self setNeedsDisplay:YES];
		return NSDragOperationCopy;
	} else {
		highlight = NO;
		dragRow = -1;
		return NSDragOperationNone;
	}
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender{
    
    if([[self window] respondsToSelector:_cmd])
        [[self window] draggingUpdated:sender];
    
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	NSPoint mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
	int row, column;
	id cell;
	
	if (![self delegate]) return NSDragOperationNone;
	
	[self getRow:&row column:&column forPoint:mouseLoc];
	cell = [self cellAtRow:row column:0];
	if (cell && (sourceDragMask & NSDragOperationCopy) &&
		[[self delegate] canReceiveDrag:sender forFormCell:cell]) {
		
		if (row != dragRow) {
			[self setKeyboardFocusRingNeedsDisplayInRect:[self cellFrameAtRow:row column:0]];
			if (highlight)
				[self setKeyboardFocusRingNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
		}
		dragRow = row;
		highlight = YES;
		return NSDragOperationCopy;
	} else {
		if (highlight)
			[self setKeyboardFocusRingNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
		highlight = NO;
		dragRow = -1;
		return NSDragOperationNone;
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender{
	if (highlight)
		[self setKeyboardFocusRingNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
    highlight = NO;
	dragRow = -1;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender{
	highlight = NO;
	[self setKeyboardFocusRingNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
	
	return (dragRow != -1);
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    if(![self delegate]) return NO;
    
	id cell = [self cellAtRow:dragRow column:0];
    dragRow = -1;
	
	return ([[self delegate] receiveDrag:sender forFormCell:cell]);
}

#pragma mark -
#pragma mark NSDraggingSource protocol

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination{
    NSString *dstPath = [dropDestination path];
    
    // queue the file creation so we don't block while waiting for this method to return
    if([promisedDragURL isFileURL]){
        [[OFMessageQueue mainQueue] queueSelector:@selector(copyPath:toPath:handler:) 
                                        forObject:[NSFileManager defaultManager]
                                       withObject:[promisedDragURL path]
                                       withObject:[dstPath stringByAppendingPathComponent:promisedDragFilename]
                                       withObject:nil];
    } else {
        [[OFMessageQueue mainQueue] queueSelector:@selector(createWeblocFileAtPath:withURL:) 
                                        forObject:[NSFileManager defaultManager]
                                       withObject:[dstPath stringByAppendingPathComponent:promisedDragFilename]
                                       withObject:promisedDragURL];
    }
    
    return [NSArray arrayWithObject:promisedDragFilename];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
    return NSDragOperationCopy;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation{
    [self setPromisedDragURL:nil];
    [self setPromisedDragFilename:nil];
}

@end

@implementation BDSKForm (Private)

// This method returns the cell at point. If there is no cell, or usingButton is YES and the point 
// is not in the button rect, nil is returned. 

- (id)cellAtPoint:(NSPoint)point usingButton:(BOOL)usingButton{
    int row, column;
	
	if (![self getRow:&row column:&column forPoint:point]) 
		return nil;
	
	BDSKFormCell *cell = (BDSKFormCell *)[self cellAtRow:row column:column];
	
	// if we use a button, we have to see if it is in the button rect
	if(usingButton){ 
		// see if there is an arrow button
		if([[self delegate] formCellHasArrowButton:cell] || [[self delegate] formCellHasFileIcon:cell]){
			NSRect aRect = [self cellFrameAtRow:row column:column];
			// check if point is in the button rect
			if( NSMouseInRect(point, [cell buttonRectForBounds:aRect], [self isFlipped]) )
				return cell;
		}            
		// there is no button, or point was outside its rect
		return nil;
	}
	
	return cell;
}

// workaround for 10.2 systems

+ (NSCursor *)fingerCursor{
    static NSCursor	*fingerCursor = nil;    
    if (fingerCursor == nil){
        if([NSCursor respondsToSelector:@selector(pointingHandCursor)]){
            fingerCursor = [NSCursor pointingHandCursor];
        } else {
            NSImage	*image = [NSImage imageNamed: @"fingerCursor"];
            fingerCursor = [[NSCursor alloc] initWithImage:image
                                                   hotSpot:NSMakePoint (8, 8)];
        }
    }
    
    return fingerCursor;
}

// used to cache the destination webloc file's URL
- (void)setPromisedDragURL:(NSURL *)theURL{
    [theURL retain];
    [promisedDragURL release];
    promisedDragURL = theURL;
}

// used to cache the filename (not the full path) of the promised file
- (void)setPromisedDragFilename:(NSString *)theFilename{
    if(promisedDragFilename != theFilename){
        [promisedDragFilename release];
        promisedDragFilename = [theFilename copy];
    }
}
    
@end
