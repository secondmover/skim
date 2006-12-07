// Copyright 1999-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFDedicatedThreadScheduler.h>

#import <Foundation/NSLock.h> // Working around precompiler bug
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSDate-OFExtensions.h>
#import <OmniFoundation/OFObject-Queue.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFDedicatedThreadScheduler.m,v 1.11 2004/02/10 04:07:47 kc Exp $")

@interface OFDedicatedThreadScheduler (Private)
- (void)notifyDedicatedThreadIfFirstEventIsSoonerThanWakeDate;
- (void)notifyDedicatedThreadThatItNeedsToWakeSooner;
- (void)mainThreadInvokeScheduledEvents;
- (void)runScheduleInCurrentThreadUntilEmpty:(BOOL)onlyUntilEmpty;
- (void)synchronouslyInvokeScheduledEvents;
- (NSDate *)wakeDate;
- (void)setWakeDate:(NSDate *)newWakeDate;
@end

enum {
    SCHEDULE_STABLE_CONDITION,
    SCHEDULE_CHANGED_CONDITION,
};

enum {
    MAIN_THREAD_IDLE,
    MAIN_THREAD_BUSY,
};

@implementation OFDedicatedThreadScheduler

static NSLock *dedicatedThreadSchedulerLock;
static OFDedicatedThreadScheduler *dedicatedThreadScheduler = nil;

+ (void)initialize;
{
    OBINITIALIZE;

    dedicatedThreadSchedulerLock = [[NSLock alloc] init];
}

+ (OFDedicatedThreadScheduler *)dedicatedThreadScheduler;
{
    if (dedicatedThreadScheduler)
        return dedicatedThreadScheduler;

    [dedicatedThreadSchedulerLock lock];
    if (dedicatedThreadScheduler == nil) {
        dedicatedThreadScheduler = [[self alloc] init];
        [dedicatedThreadScheduler runScheduleForeverInNewThread];
    }
    [dedicatedThreadSchedulerLock unlock];
    return dedicatedThreadScheduler;
}

// Init and dealloc

- init;
{
    if (![super init])
        return nil;
    scheduleConditionLock = [[NSConditionLock alloc] initWithCondition:SCHEDULE_STABLE_CONDITION];
    mainThreadSynchronizationLock = [[NSConditionLock alloc] initWithCondition:MAIN_THREAD_IDLE];
    wakeDate = nil;
    wakeDateLock = [[NSLock alloc] init];
    flags.invokesEventsInMainThread = YES;
    
    return self;
}

- (void)dealloc;
{
    [scheduleConditionLock release];
    [mainThreadSynchronizationLock release];
    [wakeDate release];
    [wakeDateLock release];
    [super dealloc];
}

// API

- (void)setInvokesEventsInMainThread:(BOOL)shouldInvokeEventsInMainThread;
{
    flags.invokesEventsInMainThread = shouldInvokeEventsInMainThread;
}

- (void)runScheduleForeverInNewThread;
{
    [NSThread detachNewThreadSelector:@selector(runScheduleForeverInCurrentThread) toTarget:self withObject:nil];
}

- (void)runScheduleForeverInCurrentThread;
{
    OMNI_POOL_START {
        [self runScheduleInCurrentThreadUntilEmpty:NO];
        NSLog(@"Did I not say 'Forever'?"); // Nobody lives forever. On the other hand, tomorrow never dies. Never say never again, though. GOOOOOLDFINGER!
    } OMNI_POOL_END;
}

// OFScheduler subclass

- (void)scheduleEvents;
{
    [self notifyDedicatedThreadIfFirstEventIsSoonerThanWakeDate];
}

- (void)cancelScheduledEvents;
{
    // No need to wake our dedicated thread, that'll just make it consume CPU sooner than it was already planning to do (when it was going to wake up to process the event).
}

// OBObject subclass

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;
    NSDate *date;
    
    debugDictionary = [super debugDictionary];
    if (scheduleConditionLock)
        [debugDictionary setObject:scheduleConditionLock forKey:@"scheduleConditionLock"];
    if ((date = [self wakeDate]))
        [debugDictionary setObject:date forKey:@"wakeDate"];

    return debugDictionary;
}

@end

@implementation OFDedicatedThreadScheduler (Private)

- (void)notifyDedicatedThreadIfFirstEventIsSoonerThanWakeDate;
{
    NSDate *currentWakeDate;
    NSDate *dateOfFirstEvent;

    dateOfFirstEvent = [self dateOfFirstEvent];
    currentWakeDate = [self wakeDate];
    // NSLog(@"[dateOfFirstEvent(%@) isBeforeDate:wakeDate(%@)] = %d", dateOfFirstEvent, wakeDate, [dateOfFirstEvent isBeforeDate:wakeDate]);
    if (dateOfFirstEvent != nil && (currentWakeDate == nil || [dateOfFirstEvent isBeforeDate:currentWakeDate])) {
        [self notifyDedicatedThreadThatItNeedsToWakeSooner];
    }
}

- (void)notifyDedicatedThreadThatItNeedsToWakeSooner;
{
    // Set the scheduleConditionLock to the 'changed' state if it isn't already
    if ([scheduleConditionLock tryLockWhenCondition:SCHEDULE_STABLE_CONDITION]) {
        // Schedule was in 'stable' state, set it to 'changed' state
        [scheduleConditionLock unlockWithCondition:SCHEDULE_CHANGED_CONDITION];
    }
}

- (void)mainThreadInvokeScheduledEvents;
{
    NSException *savedException = nil;

    [mainThreadSynchronizationLock lockWhenCondition:MAIN_THREAD_BUSY];
    NS_DURING {
        [self invokeScheduledEvents];
    } NS_HANDLER {
        savedException = localException;
    } NS_ENDHANDLER;
    [mainThreadSynchronizationLock unlockWithCondition:MAIN_THREAD_IDLE];
    if (savedException != nil)
        [savedException raise];
}

- (void)runScheduleInCurrentThreadUntilEmpty:(BOOL)onlyUntilEmpty;
{
    BOOL continueRunning = YES;

    [[self retain] autorelease];
    while (continueRunning) {
        OMNI_POOL_START {
            NSDate *dateOfFirstEvent;

            // Reset the scheduleConditionLock to the 'stable' state if it isn't already
            if ([scheduleConditionLock tryLockWhenCondition:SCHEDULE_CHANGED_CONDITION]) {
                [scheduleConditionLock unlockWithCondition:SCHEDULE_STABLE_CONDITION];
            }
            dateOfFirstEvent = [self dateOfFirstEvent];
            if (!dateOfFirstEvent && !onlyUntilEmpty) {
                dateOfFirstEvent = [NSDate distantFuture];
            }
            [self setWakeDate:dateOfFirstEvent];
            if (dateOfFirstEvent) {
                if (OFSchedulerDebug)
                    NSLog(@"%@: Sleeping until %@", [self shortDescription], [dateOfFirstEvent description]);
                if ([scheduleConditionLock lockWhenCondition:SCHEDULE_CHANGED_CONDITION beforeDate:dateOfFirstEvent]) {
                    if (OFSchedulerDebug)
                        NSLog(@"%@: Schedule changed", [self shortDescription]);
                    // Schedule changed, get the updated date of first event
                    dateOfFirstEvent = [self dateOfFirstEvent];
                    [scheduleConditionLock unlockWithCondition:SCHEDULE_STABLE_CONDITION];
                }
                if (dateOfFirstEvent && [dateOfFirstEvent timeIntervalSinceNow] < 0.0) {
                    // The first event is ready to be invoked
                    [self synchronouslyInvokeScheduledEvents];
                }
            } else {
                continueRunning = NO;
            }
        } OMNI_POOL_END;
    }
    // -run never exits unless an exception is raised
}

- (void)synchronouslyInvokeScheduledEvents;
{
    // Synchronously invoke the events, whichever the thread
    if (flags.invokesEventsInMainThread) {
        [mainThreadSynchronizationLock lock];
        [mainThreadSynchronizationLock unlockWithCondition:MAIN_THREAD_BUSY];
        [self mainThreadPerformSelector:
            @selector(mainThreadInvokeScheduledEvents)];
        [mainThreadSynchronizationLock lockWhenCondition:MAIN_THREAD_IDLE];
        [mainThreadSynchronizationLock unlock];
    } else {
        [self invokeScheduledEvents];
    }
}

- (NSDate *)wakeDate;
{
    NSDate *savedWakeDate;

    [wakeDateLock lock];
    savedWakeDate = [wakeDate retain];
    [wakeDateLock unlock];
    return [savedWakeDate autorelease];
}

- (void)setWakeDate:(NSDate *)newWakeDate;
{
    [wakeDateLock lock];
    [wakeDate release];
    wakeDate = [newWakeDate retain];
    [wakeDateLock unlock];
}

@end
