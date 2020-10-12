//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIWindow+SRGLetterbox.h"

@implementation UIWindow (SRGLetterbox)

- (UIViewController *)srg_letterboxTopViewController
{
    UIViewController *topViewController = self.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

@end
