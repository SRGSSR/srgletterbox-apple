//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGFocusableButton.h"

static CGFloat kFocusedScaleFactor = 1.2f;

static void commonInit(SRGFocusableButton *self)
{
    // The focus effect alone is sufficient, no need for highlighting by default
    self.adjustsImageWhenHighlighted = NO;
}

@implementation SRGFocusableButton

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{    
    [coordinator addCoordinatedAnimations:^{
        [UIView animateWithDuration:UIView.inheritedAnimationDuration animations:^{
            [self updateAppearanceFocused:self.focused];
        }];
    } completion:nil];
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    [super pressesBegan:presses withEvent:event];
    
    if (presses.anyObject.type == UIPressTypeSelect) {
        [UIView animateWithDuration:0.2 animations:^{
            [self updateAppearanceFocused:NO];
        } completion:nil];
    }
}

- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    [super pressesCancelled:presses withEvent:event];
    
    [self pressesFinished:presses withEvent:event];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    [super pressesEnded:presses withEvent:event];
    
    [self pressesFinished:presses withEvent:event];
}

- (void)pressesFinished:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    if (presses.anyObject.type == UIPressTypeSelect) {
        [UIView animateWithDuration:0.2 animations:^{
            [self updateAppearanceFocused:self.focused];
        } completion:nil];
    }
}

#pragma mark Appearance

- (void)updateAppearanceFocused:(BOOL)focused
{
    if (focused) {
        self.transform = CGAffineTransformMakeScale(kFocusedScaleFactor, kFocusedScaleFactor);
        self.layer.shadowRadius = 10.f;
        self.layer.shadowOpacity = 0.3f;
        self.layer.shadowOffset = CGSizeMake(0.f, 20.f);
    }
    else {
        self.transform = CGAffineTransformIdentity;
        self.layer.shadowRadius = 0.f;
        self.layer.shadowOpacity = 0.f;
        self.layer.shadowOffset = CGSizeZero;
    }
}

@end
