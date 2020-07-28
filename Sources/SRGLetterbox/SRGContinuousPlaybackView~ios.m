//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGContinuousPlaybackView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxView+Private.h"
#import "SRGRemainingTimeButton.h"
#import "UIImageView+SRGLetterbox.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGAppearance;

@interface SRGContinuousPlaybackView ()

@property (nonatomic, weak) UILabel *introLabel;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *subtitleLabel;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) SRGRemainingTimeButton *remainingTimeButton;
@property (nonatomic, weak) UIStackView *cancelButtonStackView;
@property (nonatomic, weak) UIButton *cancelButton;

@end

@implementation SRGContinuousPlaybackView

#pragma mark Layout

- (void)createView
{
    [super createView];
    
    [self createImageBackgroundInView:self];
    [self creatDimmingViewInView:self];
    [self createMainLayoutInView:self];
}

- (void)createImageBackgroundInView:(UIView *)view
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [view addSubview:imageView];
    self.imageView = imageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
}

- (void)creatDimmingViewInView:(UIView *)view
{
    UIView *dimmingView = [[UIView alloc] init];
    dimmingView.translatesAutoresizingMaskIntoConstraints = NO;
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
    [view addSubview:dimmingView];
    
    [NSLayoutConstraint activateConstraints:@[
        [dimmingView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [dimmingView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [dimmingView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [dimmingView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
}

- (void)createMainLayoutInView:(UIView *)view
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.spacing = 2.f;
    [view addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];
    
    if (@available(iOS 11, *)) {
        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor constant:16.f],
            [stackView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor constant:-16.f]
        ]];
    }
    else {
        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:16.f],
            [stackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-16.f]
        ]];
    }
    
    UIView *topSpacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:topSpacerView];
    
    [self createIntroLabelInStackView:stackView];
    [self createTitleLabelInStackView:stackView];
    [self createSubtitleLabelInStackView:stackView];
    [self createFixedSpacerWithHeight:6.f inStackView:stackView];
    [self createRemainingTimeButtonInStackView:stackView];
    [self createFixedSpacerWithHeight:6.f inStackView:stackView];
    [self createCancelButtonInStackView:stackView];
    
    UIView *bottomSpacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:bottomSpacerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [topSpacerView.heightAnchor constraintEqualToAnchor:bottomSpacerView.heightAnchor]
    ]];
}

- (void)createFixedSpacerWithHeight:(CGFloat)height inStackView:(UIStackView *)stackView
{
    UIView *fixedSpacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:fixedSpacerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [fixedSpacerView.heightAnchor constraintEqualToConstant:height]
    ]];
}

- (void)createIntroLabelInStackView:(UIStackView *)stackView
{
    UILabel *introLabel = [[UILabel alloc] init];
    introLabel.text = SRGLetterboxLocalizedString(@"Next", @"For continuous playback, introductory label for content which is about to start");
    introLabel.textColor = UIColor.lightGrayColor;
    introLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:introLabel];
    self.introLabel = introLabel;
}

- (void)createTitleLabelInStackView:(UIStackView *)stackView
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:titleLabel];
    self.titleLabel = titleLabel;
}

- (void)createSubtitleLabelInStackView:(UIStackView *)stackView
{
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.textColor = UIColor.lightGrayColor;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:subtitleLabel];
    self.subtitleLabel = subtitleLabel;
}

- (void)createRemainingTimeButtonInStackView:(UIStackView *)stackView
{
    UIStackView *remainingTimeButtonStackView = [[UIStackView alloc] init];
    remainingTimeButtonStackView.axis = UILayoutConstraintAxisHorizontal;
    remainingTimeButtonStackView.alignment = UIStackViewAlignmentFill;
    remainingTimeButtonStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:remainingTimeButtonStackView];
    
    UIView *remainingTimeButtonLeadingSpacerView = [[UIView alloc] init];
    [remainingTimeButtonStackView addArrangedSubview:remainingTimeButtonLeadingSpacerView];
    
    SRGRemainingTimeButton *remainingTimeButton = [[SRGRemainingTimeButton alloc] init];
    remainingTimeButton.tintColor = UIColor.whiteColor;
    [remainingTimeButton setImage:[UIImage srg_letterboxImageNamed:@"play_centered"] forState:UIControlStateNormal];
    [remainingTimeButton addTarget:self action:@selector(playUpcomingMedia:) forControlEvents:UIControlEventTouchUpInside];
    [remainingTimeButtonStackView addArrangedSubview:remainingTimeButton];
    self.remainingTimeButton = remainingTimeButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [remainingTimeButton.widthAnchor constraintEqualToConstant:55.f],
        [remainingTimeButton.heightAnchor constraintEqualToConstant:55.f]
    ]];
    
    UIView *remainingTimeButtonTrailingSpacerView = [[UIView alloc] init];
    [remainingTimeButtonStackView addArrangedSubview:remainingTimeButtonTrailingSpacerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [remainingTimeButtonLeadingSpacerView.widthAnchor constraintEqualToAnchor:remainingTimeButtonTrailingSpacerView.widthAnchor]
    ]];
}

- (void)createCancelButtonInStackView:(UIStackView *)stackView
{
    UIStackView *cancelButtonStackView = [[UIStackView alloc] init];
    cancelButtonStackView.axis = UILayoutConstraintAxisHorizontal;
    cancelButtonStackView.alignment = UIStackViewAlignmentFill;
    cancelButtonStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:cancelButtonStackView];
    self.cancelButtonStackView = cancelButtonStackView;
    
    UIView *cancelButtonLeadingSpacerView = [[UIView alloc] init];
    [cancelButtonStackView addArrangedSubview:cancelButtonLeadingSpacerView];
    
    UIButton *cancelButton = [[UIButton alloc] init];
    [cancelButton setTitle:SRGLetterboxLocalizedString(@"Cancel", @"Title of a cancel button") forState:UIControlStateNormal];
    cancelButton.titleLabel.textColor = UIColor.whiteColor;
    [cancelButton addTarget:self action:@selector(cancelContinuousPlayback:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButtonStackView addArrangedSubview:cancelButton];
    self.cancelButton = cancelButton;
     
    UIView *cancelButtonTrailingSpacerView = [[UIView alloc] init];
    [cancelButtonStackView addArrangedSubview:cancelButtonTrailingSpacerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [cancelButtonLeadingSpacerView.widthAnchor constraintEqualToAnchor:cancelButtonTrailingSpacerView.widthAnchor]
    ]];
}

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.introLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.titleLabel.font = [UIFont srg_boldFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.cancelButton.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGLetterboxController *controller = self.controller;
    [controller removeObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia)];
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    SRGLetterboxController *controller = self.controller;
    
    @weakify(self)
    [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self refresh];
        [self.parentLetterboxView setNeedsLayoutAnimated:YES];
    }];
    
    [self refresh];
    [self updateLayout];
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.alpha = (self.controller.continuousPlaybackUpcomingMedia) ? 1.f : 0.f;
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    [self updateLayout];
}

#pragma mark UI

- (void)refresh
{
    // Only update with valid upcoming information
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    if (upcomingMedia) {
        self.titleLabel.text = upcomingMedia.title;
        
        NSString *showTitle = upcomingMedia.show.title;
        if (showTitle && ! [showTitle isEqualToString:upcomingMedia.title]) {
            self.subtitleLabel.text = upcomingMedia.show.title;
        }
        else {
            self.subtitleLabel.text = nil;
        }
        
        [self.imageView srg_requestImageForObject:upcomingMedia withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
        
        NSTimeInterval duration = [self.controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate];
        float progress = (duration != 0) ? ([NSDate.date timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate]) / duration : 1.f;
        [self.remainingTimeButton setProgress:progress withDuration:duration];
    }
}

- (void)updateLayout
{
    self.introLabel.hidden = NO;
    self.titleLabel.hidden = NO;
    self.subtitleLabel.hidden = NO;
    self.cancelButtonStackView.hidden = NO;
    self.remainingTimeButton.enabled = YES;
    
    if (self.controller.continuousPlaybackUpcomingMedia) {
        if (! self.parentLetterboxView.userInterfaceEnabled) {
            self.remainingTimeButton.enabled = NO;
            self.cancelButtonStackView.hidden = YES;
        }
        
        CGFloat height = CGRectGetHeight(self.frame);
        if (height < 200.f) {
            self.introLabel.hidden = YES;
            self.subtitleLabel.hidden = YES;
        }
        if (height < 150.f) {
            self.cancelButtonStackView.hidden = YES;
        }
        if (height < 100.f) {
            self.titleLabel.hidden = YES;
        }
    }
    else {
        self.cancelButtonStackView.hidden = YES;
    }
}

#pragma mark Actions

- (void)cancelContinuousPlayback:(id)sender
{
    // Save media informations since cancelling will change it
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    [self.controller cancelContinuousPlayback];
    [self.delegate continuousPlaybackView:self didCancelWithUpcomingMedia:upcomingMedia];
}

- (void)playUpcomingMedia:(id)sender
{
    // Save media information since playing will change it
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    if ([self.controller playUpcomingMedia]) {
        [self.delegate continuousPlaybackView:self didEngageWithUpcomingMedia:upcomingMedia];
    }
}

@end

#endif
