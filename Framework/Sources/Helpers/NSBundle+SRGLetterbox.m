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
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundle = [NSBundle bundleForClass:[SRGLetterboxController class]];
    });
    return bundle;
}

@end
