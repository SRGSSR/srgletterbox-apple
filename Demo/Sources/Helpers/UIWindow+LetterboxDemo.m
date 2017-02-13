//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIWindow+LetterboxDemo.h"

@implementation UIWindow (LetterboxDemo)

- (UIViewController *)topPresentedViewController
{
    UIViewController *topPresentedViewController = self.rootViewController;
    while (topPresentedViewController.presentedViewController) {
        topPresentedViewController = topPresentedViewController.presentedViewController;
    }
    return topPresentedViewController;
}

@end
