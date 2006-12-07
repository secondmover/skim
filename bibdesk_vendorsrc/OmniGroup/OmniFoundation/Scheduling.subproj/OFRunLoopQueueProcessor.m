// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFRunLoopQueueProcessor.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFMessageQueue.h>
#import <OmniFoundation/NSThread-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFRunLoopQueueProcessor.m,v 1.15 2004/02/10 04:07:47 kc Exp $")

static OFRunLoopQueueProcessor *mainThreadProcessor = nil;

@implementation OFRunLoopQueueProcessor

+ (void)didLoad;
{
    Class mainThreadRunLoopProcessorClass;

    [NSThread setMainThread];
    
    mainThreadRunLoopProcessorClass = [self mainThreadRunLoopProcessorClass];
    mainThreadProcessor = [[mainThreadRunLoopProcessorClass alloc] initForQueue:[OFMessageQueue mainQueue]];

    // Call the +mainThreadRunLoopModes method so categories (in OmniAppKit, say) can add more modes
    if (![NSThread inMainThread])
        [NSException raise:@"OFRunLoopQueueProcessorWrongThread" format:@"Attempted to start the main thread's OFRunLoopQueueProcessor from a thread other than the main thread"];

    [mainThreadProcessor runFromCurrentRunLoopInModes:[self mainThreadRunLoopModes]];
}

+ (Class)mainThreadRunLoopProcessorClass;
{
    return self;
}

+ (NSArray *)mainThreadRunLoopModes;
{
    return [NSArray arrayWithObjects:NSDefaultRunLoopMode, nil];
}

+ (OFRunLoopQueueProcessor *)mainThreadProcessor;
{
    return mainThreadProcessor;
}

+ (void)disableMainThreadQueueProcessing;
{
    [mainThreadProcessor disable];
}

+ (void)reenableMainThreadQueueProcessing;
{
    [mainThreadProcessor enable];
}

- initForQueue:(OFMessageQueue *)aQueue;
{
    if (![super initForQueue:aQueue])
        return nil;

    [messageQueue setDelegate:self];

    notificationPort = [[NSPort port] retain];
    [notificationPort setDelegate:self];

    portMessage = [[NSPortMessage alloc] initWithSendPort:notificationPort receivePort:notificationPort components:nil];

    return self;
}

- (void)dealloc;
{
    [notificationPort setDelegate:nil];
    [notificationPort release];
    [portMessage release];
    [super dealloc];
}

//

- (void)runFromCurrentRunLoopInModes:(NSArray *)modes;
{
    unsigned int modeIndex, modeCount;
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

    modeCount = [modes count];
    for (modeIndex = 0; modeIndex < modeCount; modeIndex++)
        [runLoop addPort:notificationPort forMode:[modes objectAtIndex:modeIndex]];

    [self processQueueUntilEmpty];
}

// OFMessageQueueDelegate protocol --- called in whatever thread enqueues the message

- (void)queueHasInvocations:(OFMessageQueue *)aQueue;
{
   if (disableCount > 0)
       return;

   if (![portMessage sendBeforeDate:[NSDate distantPast]]) {
       // If this fails, then the port is probably full, meaning that we've already notified
   }
}

// NSPort delegate method --- called by our registered runloop in its thread

- (void)handlePortMessage:(NSPortMessage *)message;
{
    if (![NSThread inMainThread]) {
        // Well, in the first place, this should never happen...
        OBASSERT([NSThread inMainThread]);
        // But since it did (presumably due to Java running the main run loop in another thread when it shouldn't), recover gracefully
        [self queueHasInvocations:nil];
        return;
    }
    if (disableCount > 0)
        return;
    [self processQueueUntilEmpty];
}

// Disallow recursive queue processing.

- (void)processQueueUntilEmpty;
{
    [self disable];
    NS_DURING {
        [super processQueueUntilEmpty];
    } NS_HANDLER {
        [self enable];
        [localException raise];
    } NS_ENDHANDLER;
    [self enable];
}

- (void)enable;
{
    if (disableCount > 0)
        disableCount--;
    if (disableCount == 0 && [messageQueue hasInvocations])
        [self queueHasInvocations:messageQueue];
}

- (void)disable;
{
    disableCount++;
}

@end
