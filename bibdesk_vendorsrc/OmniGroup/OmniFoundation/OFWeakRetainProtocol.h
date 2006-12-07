// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFWeakRetainProtocol.h,v 1.7 2004/02/10 04:07:41 kc Exp $

@protocol OFWeakRetain
// Must be implemented by the class itself
- (void)invalidateWeakRetains;

// Implemented by the OFWeakRetainConcreteImplementation_IMPLEMENTATION macro
- (void)incrementWeakRetainCount;
- (void)decrementWeakRetainCount;
@end
