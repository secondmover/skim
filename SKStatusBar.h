//
//  SKStatusBar.h
//  Skim
//
//  Created by Christiaan Hofman on 7/8/07.
/*
 This software is Copyright (c) 2007-2009
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import <Cocoa/Cocoa.h>

enum {
   SKProgressIndicatorNone = -1,
   SKProgressIndicatorBarStyle = NSProgressIndicatorBarStyle,
   SKProgressIndicatorSpinningStyle = NSProgressIndicatorSpinningStyle
};
typedef NSInteger SKProgressIndicatorStyle;


@interface SKStatusBar : NSView {
	id leftCell;
	id rightCell;
    id iconCell;
	NSProgressIndicator *progressIndicator;
    NSTrackingRectTag leftTrackingRectTag;
    NSTrackingRectTag rightTrackingRectTag;
    BOOL animating;
}

- (void)toggleBelowView:(NSView *)view animate:(BOOL)animate;

- (BOOL)isVisible;
- (BOOL)isAnimating;

- (NSString *)leftStringValue;
- (void)setLeftStringValue:(NSString *)aString;

- (NSAttributedString *)leftAttributedStringValue;
- (void)setLeftAttributedStringValue:(NSAttributedString *)object;

- (NSString *)rightStringValue;
- (void)setRightStringValue:(NSString *)aString;

- (NSAttributedString *)rightAttributedStringValue;
- (void)setRightAttributedStringValue:(NSAttributedString *)object;

- (SEL)leftAction;
- (void)setLeftAction:(SEL)selector;

- (id)leftTarget;
- (void)setLeftTarget:(id)newTarget;

- (SEL)rightAction;
- (void)setRightAction:(SEL)selector;

- (id)rightTarget;
- (void)setRightTarget:(id)newTarget;

- (NSInteger)leftState;
- (void)setLeftState:(NSInteger)newState;

- (NSInteger)rightState;
- (void)setRightState:(NSInteger)newState;

- (NSInteger)state;
- (void)setState:(NSInteger)newState;

- (NSFont *)font;
- (void)setFont:(NSFont *)fontObject;

- (id)iconCell;
- (void)setIconCell:(id)newIconCell;

- (NSProgressIndicator *)progressIndicator;

- (SKProgressIndicatorStyle)progressIndicatorStyle;
- (void)setProgressIndicatorStyle:(SKProgressIndicatorStyle)style;

- (void)startAnimation:(id)sender;
- (void)stopAnimation:(id)sender;

@end
