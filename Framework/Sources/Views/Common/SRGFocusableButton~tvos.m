//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGFocusableButton.h"

@implementation SRGFocusableButton

#pragma mark Overrides

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{    
    [coordinator addCoordinatedAnimations:^{
        if (context.nextFocusedView == self) {
            [UIView animateWithDuration:UIView.inheritedAnimationDuration animations:^{
                self.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
            }];
        }
        else if (context.previouslyFocusedView == self) {
            [UIView animateWithDuration:UIView.inheritedAnimationDuration animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }
    } completion:nil];
}

@end
