//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSTimer+SRGLetterbox.h"

#import "SRGTimerTarget.h"

@implementation NSTimer (SRGLetterbox)

+ (NSTimer *)srg_scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * _Nonnull timer))block
{
    if ([[self class] instancesRespondToSelector:@selector(scheduledTimerWithTimeInterval:repeats:block:)]) {
        return [self scheduledTimerWithTimeInterval:interval repeats:repeats block:block];
    }
    else {
        // Do not use self as target, since this would lead to subtle issues when the timer is deallocated
        SRGTimerTarget *target = [[SRGTimerTarget alloc] initWithBlock:block];
        return [self scheduledTimerWithTimeInterval:interval target:target selector:@selector(fire:) userInfo:nil repeats:repeats];
    }
}

@end
