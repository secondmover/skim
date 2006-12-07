// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFZone.h,v 1.13 2004/02/10 04:07:41 kc Exp $

#import <OmniFoundation/OFObject.h>

/*" OFZone is a simple Objective-C wrapper around an NSZone pointer to allow reference counting (in particular, autoreleasing). When the OFZone is deallocated, it calls NSRecycleZone(). "*/

@interface OFZone : OFObject
{
    BOOL ownsZone;
@public
    NSZone *zone;  /*" The allocation zone represented by this OFZone. "*/
}

+ (OFZone *)zoneForNSZone:(NSZone *)aZone;
+ (OFZone *)zoneForObject:(id <NSObject>)anObject;
+ (OFZone *)defaultZone;
+ (OFZone *)newZone;

- (NSZone *)nsZone;  /* NB: -[OFZone zone] returns the zone the OFZone is allocated *in*, not the zone it *represents* ! */

- (void)setName:(NSString *)newName;
- (NSString *)name;

@end
