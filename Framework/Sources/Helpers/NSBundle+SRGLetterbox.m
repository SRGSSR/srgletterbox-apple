//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+SRGLetterbox.h"

#import "SRGLetterboxView.h"

@implementation NSBundle (SRGAnalytics)

+ (instancetype)srg_letterboxBundle
{
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        bundle = [NSBundle bundleForClass:[SRGLetterboxView class]];
    });
    return bundle;
}

@end
