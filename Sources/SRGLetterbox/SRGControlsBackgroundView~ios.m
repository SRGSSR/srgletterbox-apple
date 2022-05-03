//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGControlsBackgroundView.h"

#import "UIImageView+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"

@interface SRGControlsBackgroundView ()

@property (nonatomic, weak) UIView *dimmingView;
@property (nonatomic, weak) UIImageView *loadingImageView;

@end

@implementation SRGControlsBackgroundView

#pragma mark Layout

- (void)layoutContentView
{
    [super layoutContentView];
    
    // Disable all user interactions so that the view does not trap gesture recognizers. Its only purpose is
    // to increase control readability and displaying the activity indicator
    self.userInteractionEnabled = NO;
    
    UIView *dimmingView = [[UIView alloc] init];
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.35f];
    dimmingView.userInteractionEnabled = NO;
    [self.contentView addSubview:dimmingView];
    self.dimmingView = dimmingView;
    
    dimmingView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [dimmingView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [dimmingView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [dimmingView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [dimmingView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
    ]];
}

#pragma mark Overrides

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden transientState:(SRGLetterboxViewTransientState)transientState
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden transientState:transientState];
    
    self.dimmingView.alpha = (! userInterfaceHidden || self.controller.loading) ? 1.f : 0.f;
    
    if (self.controller.loading) {
        self.loadingImageView.alpha = 1.f;
        [self.loadingImageView startAnimating];
    }
    else {
        self.loadingImageView.alpha = 0.f;
    }
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden transientState:(SRGLetterboxViewTransientState)transientState
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden transientState:transientState];
    
    // Lazily add view when needed, mitigating associated costs
    if (self.controller.loading && ! self.loadingImageView) {
        UIImageView *loadingImageView = [UIImageView srg_loadingImageViewWithTintColor:UIColor.whiteColor];
        [loadingImageView startAnimating];
        [self.contentView addSubview:loadingImageView];
        self.loadingImageView = loadingImageView;
        
        loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [loadingImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [loadingImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
        ]];
    }
}

@end

#endif
