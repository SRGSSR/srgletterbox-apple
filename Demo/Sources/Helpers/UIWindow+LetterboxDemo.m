//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIWindow+LetterboxDemo.h"

@implementation UIWindow (LetterboxDemo)

- (UIViewController *)letterbox_demo_topViewController
{
    UIViewController *topViewController = self.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

- (void)letterbox_demo_updateFocus
{
    // Focus updates can be triggered locally (e.g. within some view or view controller hierarchy), but in some cases
    // we might want to reconsider focus for the currently displayed view controller hierarchy. Focus can namely only
    // be moved if the update is requested in a focused view parent, so in some cases it is useful to trigger such
    // an update at the top of the view hierarchy.
    // See https://medium.com/airbnb-engineering/mastering-the-tvos-focus-engine-f8a13b371083
    UIView *topView = self.letterbox_demo_topViewController.viewIfLoaded;
    [topView setNeedsFocusUpdate];
    [topView updateFocusIfNeeded];
}

@end
