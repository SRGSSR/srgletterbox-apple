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
