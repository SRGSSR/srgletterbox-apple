//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSTimer+SRGLetterbox.h"

#import "SRGLetterboxTimerTarget.h"

@implementation NSTimer (SRGLetterbox)

+ (NSTimer *)srgletterbox_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * _Nonnull timer))block
{
    NSTimer *timer = nil;
    
    if (@available(iOS 10, tvOS 10, *)) {
        timer = [self timerWithTimeInterval:interval repeats:repeats block:block];
    }
    else {
        // Do not use self as target, since this would lead to subtle issues when the timer is deallocated
        SRGLetterboxTimerTarget *target = [[SRGLetterboxTimerTarget alloc] initWithBlock:block];
        timer = [self timerWithTimeInterval:interval target:target selector:@selector(fire:) userInfo:nil repeats:repeats];
    }
    
    // Use the recommended 10% tolerance as default, see `tolerance` documentation
    timer.tolerance = interval / 10.;
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

@end
