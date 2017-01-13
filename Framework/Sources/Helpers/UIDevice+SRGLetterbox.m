//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIDevice+SRGLetterbox.h"

static BOOL s_locked = NO;

// Function declarations
static void lockComplete(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@implementation UIDevice (SRGLetterbox)

#pragma mark Class methods

+ (BOOL)srg_isLocked
{
    return s_locked;
}

#pragma mark Notifications

+ (void)srg_letterbox_applicationDidBecomeActive:(NSNotification *)notification
{
    s_locked = NO;
}

@end

#pragma mark Functions

__attribute__((constructor)) static void UIDevicePlayUtilsInit(void)
{
    // Differentiate between device lock and application sent to the background
    // See http://stackoverflow.com/a/9058038/760435
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)[UIDevice class],
                                    lockComplete,
                                    CFSTR("com.apple.springboard.lockcomplete"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    [[NSNotificationCenter defaultCenter] addObserver:[UIDevice class]
                                             selector:@selector(srg_letterbox_applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

static void lockComplete(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    s_locked = YES;
}
