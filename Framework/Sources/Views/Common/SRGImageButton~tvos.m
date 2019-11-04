//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGImageButton.h"

static void commonInit(SRGImageButton *self);

@interface SRGImageButton ()

@property (nonatomic) UIImageView *imageView;

@end

@implementation SRGImageButton

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

#pragma mark Focus

- (BOOL)canBecomeFocused
{
    return YES;
}

#pragma mark Interactions

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    [super pressesBegan:presses withEvent:event];
    
    if (presses.anyObject.type == UIPressTypeSelect) {
        [UIView animateWithDuration:0.2 animations:^{
            [self updateAppearancePressed:YES];
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
            [self updateAppearancePressed:NO];
        } completion:^(BOOL finished) {
            [self sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
        }];
    }
}

#pragma mark Appearance management

- (void)updateAppearancePressed:(BOOL)pressed
{
    if (pressed) {
        self.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
    }
    else {
        self.transform = CGAffineTransformIdentity;
    }
}

#pragma mark Accessibility

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end

static void commonInit(SRGImageButton *self)
{
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.adjustsImageWhenAncestorFocused = YES;
    [self addSubview:self.imageView];
    
    self.userInteractionEnabled = YES;
}
