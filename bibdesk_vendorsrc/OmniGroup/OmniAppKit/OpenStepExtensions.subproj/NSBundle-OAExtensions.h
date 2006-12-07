// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSBundle-OAExtensions.h,v 1.11 2004/02/10 04:07:33 kc Exp $

#import <Foundation/NSBundle.h>

@interface NSBundle (OAExtensions)
- (void)loadNibNamed:(NSString *)nibName owner:(id <NSObject>)owner;
    // Raises an exception if unable to load successfully
@end
