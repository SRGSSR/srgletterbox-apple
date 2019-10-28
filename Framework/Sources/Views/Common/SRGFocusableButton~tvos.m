//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGFocusableButton.h"

static CGFloat kFocusedScaleFactor = 1.05f;

@interface SRGFocusableButton ()

@property (nonatomic, weak) UIView *unfocusedShadowView;
@property (nonatomic, weak) UIView *focusedShadowView;

- (void)updateAppearanceFocused:(BOOL)focused;

@end

static void commonInit(SRGFocusableButton *self)
{
    self.backgroundColor = UIColor.redColor;
    
    // Fill the frame
    self.contentEdgeInsets = UIEdgeInsetsZero;
    
    // Fill the button with images by default
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    
    // The focus effect alone is sufficient, no need for highlighting by default
    self.adjustsImageWhenHighlighted = NO;
    self.clipsToBounds = NO;
    
    // Avoid seeing shadows through the image
    self.imageView.opaque = YES;
    
    // Use two separate transparent views to hold shadows, which we can the animate.
    UIView *unfocusedShadowView = [[UIView alloc] init];
    unfocusedShadowView.backgroundColor = UIColor.clearColor;
    unfocusedShadowView.layer.shadowOffset = CGSizeMake(0.f, 10.f);
    unfocusedShadowView.layer.shadowRadius = 5.f;
    unfocusedShadowView.layer.shadowOpacity = 0.3f;
    [self insertSubview:unfocusedShadowView atIndex:0];
    self.unfocusedShadowView = unfocusedShadowView;
    
    UIView *focusedShadowView = [[UIView alloc] init];
    focusedShadowView.backgroundColor = UIColor.clearColor;
    focusedShadowView.layer.shadowOffset = CGSizeMake(0.f, 20.f);
    focusedShadowView.layer.shadowRadius = 10.f;
    focusedShadowView.layer.shadowOpacity = 0.3f;
    [self insertSubview:focusedShadowView atIndex:0];
    self.focusedShadowView = focusedShadowView;
    
    [self updateAppearanceFocused:NO];
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect imageViewFrame = self.imageView.frame;
    if (! CGRectIsNull(imageViewFrame)) {
        self.unfocusedShadowView.layer.shadowPath = [UIBezierPath bezierPathWithRect:imageViewFrame].CGPath;
        self.focusedShadowView.layer.shadowPath = [UIBezierPath bezierPathWithRect:imageViewFrame].CGPath;
    }
    else {
        self.unfocusedShadowView.layer.shadowPath = nil;
        self.focusedShadowView.layer.shadowPath = nil;
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{    
    [coordinator addCoordinatedAnimations:^{
        [UIView animateWithDuration:UIView.inheritedAnimationDuration animations:^{
            if (context.previouslyFocusedView == self) {
                [self updateAppearanceFocused:NO];
            }
            else if (context.nextFocusedView == self) {
                [self updateAppearanceFocused:YES];
            }
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
        self.unfocusedShadowView.alpha = 0.f;
        self.focusedShadowView.alpha = 1.f;
        self.transform = CGAffineTransformMakeScale(kFocusedScaleFactor, kFocusedScaleFactor);
    }
    else {
        self.unfocusedShadowView.alpha = 1.f;
        self.focusedShadowView.alpha = 0.f;
        self.transform = CGAffineTransformIdentity;
    }
}

@end
