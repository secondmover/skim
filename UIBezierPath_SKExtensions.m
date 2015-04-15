//
//  UIBezierPath_SKExtensions.m
//  Skim
//
//  Created by Adam Maxwell on 10/22/05.
/*
 This software is Copyright (c) 2005-2013
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

#import "UIBezierPath_SKExtensions.h"
#import "UIGeometry_SKExtensions.h"


@implementation UIBezierPath (SKExtensions)

+ (UIBezierPath *)bezierPathWithLeftRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = fmin(radius, fmin(0.5f * CGRectGetHeight(rect), CGRectGetWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    CGRect innerRect = SKShrinkRect(CGRectInset(rect, 0.0, radius), radius, CGRectMinXEdge); // Make rect with corners being centers of the corner circles.
    UIBezierPath *path = [self bezierPath];
    
    // Now draw our rectangle:
    [path moveToPoint: CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
    
    // Right edge:
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    // Top edge and top left:
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(innerRect), CGRectGetMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0 clockwise:FALSE];
    // Left edge and bottom left:
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(innerRect), CGRectGetMinY(innerRect)) radius:radius startAngle:180.0  endAngle:270.0 clockwise:FALSE];
    // Bottom edge:
    [path closePath];
    
    return path;
}

+ (UIBezierPath *)bezierPathWithRightRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = fmin(radius, fmin(0.5f * CGRectGetHeight(rect), CGRectGetWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    CGRect innerRect = SKShrinkRect(CGRectInset(rect, 0.0, radius), radius, CGRectMaxXEdge); // Make rect with corners being centers of the corner circles.
    UIBezierPath *path = [self bezierPath];
    
    // Now draw our rectangle:
    [path moveToPoint: CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
    
    // Left edge:
    [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
    // Bottom edge and bottom right:
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(innerRect), CGRectGetMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0 clockwise:FALSE];
    // Right edge and top right:
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(innerRect), CGRectGetMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 clockwise:FALSE];
    // Top edge:
    [path closePath];
    
    return path;
}

- (NSArray *)dashPattern {
    NSInteger i, count = 0;
    NSMutableArray *array = [NSMutableArray array];
    [self getLineDash:NULL count:&count phase:NULL];
    if (count > 0) {
        CGFloat pattern[count];
        [self getLineDash:pattern count:&count phase:NULL];
        for (i = 0; i < count; i++)
            [array addObject:[NSNumber numberWithDouble:pattern[i]]];
    }
    return array;
}

- (void)setDashPattern:(NSArray *)newPattern {
    NSInteger i, count = [newPattern count];
    CGFloat pattern[count];
    for (i = 0; i< count; i++)
        pattern[i] = [[newPattern objectAtIndex:i] doubleValue];
    [self setLineDash:pattern count:count phase:0];
}

//- (CGPoint)associatedPointForElementAtIndex:(NSUInteger)anIndex {
//    CGPoint points[3];
//    if (NSCurveToBezierPathElement == [self elementAtIndex:anIndex associatedPoints:points])
//        return points[2];
//    else
//        return points[0];
//}
//
//- (CGRect)nonEmptyBounds {
//    CGRect bounds = [self bounds];
//    if (CGRectIsEmpty(bounds) && [self elementCount]) {
//        CGPoint point, minPoint = CGZeroPoint, maxPoint = CGZeroPoint;
//        NSUInteger i, count = [self elementCount];
//        for (i = 0; i < count; i++) {
//            point = [self associatedPointForElementAtIndex:i];
//            if (i == 0) {
//                minPoint = maxPoint = point;
//            } else {
//                minPoint.x = fmin(minPoint.x, point.x);
//                minPoint.y = fmin(minPoint.y, point.y);
//                maxPoint.x = fmax(maxPoint.x, point.x);
//                maxPoint.y = fmax(maxPoint.y, point.y);
//            }
//        }
//        bounds = CGRectMake(minPoint.x - 0.1, minPoint.y - 0.1, maxPoint.x - minPoint.x + 0.2, maxPoint.y - minPoint.y + 0.2);
//    }
//    return bounds;
//}

@end

