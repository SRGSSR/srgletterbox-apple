//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGLetterbox.h"

#import "SRGLetterboxController.h"

NSString *SRGLetterboxNonLocalizedString(NSString *string)
{
    return string;
}

@implementation NSBundle (SRGLetterbox)

#pragma mark Class methods

+ (instancetype)srg_letterboxBundle
{
    static NSBundle *s_bundle;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:SRGLetterboxController.class].bundlePath stringByAppendingPathComponent:@"SRGLetterbox.bundle"];
        s_bundle = [NSBundle bundleWithPath:bundlePath];
        NSAssert(s_bundle, @"Please add SRGLetterbox.bundle to your project resources");
    });
    return s_bundle;
}

+ (BOOL)srg_letterbox_isProductionVersion
{
    // Check SIMULATOR_DEVICE_NAME for iOS 9 and above, device name below
    if (NSProcessInfo.processInfo.environment[@"SIMULATOR_DEVICE_NAME"]
            || [UIDevice.currentDevice.name.lowercaseString containsString:@"simulator"]) {
        return NO;
    }
    
    if ([NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]) {
        return NO;
    }
    
    return (NSBundle.mainBundle.appStoreReceiptURL != nil);
}

@end
