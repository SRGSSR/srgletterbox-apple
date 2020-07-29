//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGErrorView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSLayoutConstraint+SRGLetterboxPrivate.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxView+Private.h"
#import "UIImage+SRGLetterbox.h"

@import SRGAppearance;

@interface SRGErrorView ()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UILabel *messageLabel;

#if TARGET_OS_IOS
@property (nonatomic, weak) UILabel *instructionsLabel;
@property (nonatomic, weak) UITapGestureRecognizer *retryTapGestureRecognizer;
#endif

@end

@implementation SRGErrorView

#pragma mark Layout

- (void)createView
{
    [super createView];
    
    self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
    
#if TARGET_OS_IOS
    UITapGestureRecognizer *retryTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retry:)];
    [self addGestureRecognizer:retryTapGestureRecognizer];
    self.retryTapGestureRecognizer = retryTapGestureRecognizer;
#endif
    
    [self createMainStackViewInView:self];
}

- (UIView *)createSpacerViewInStackView:(UIStackView *)stackView
{
    UIView *spacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:spacerView];
    return spacerView;
}

- (void)createMainStackViewInView:(UIView *)view
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
#if TARGET_OS_TV
    stackView.spacing = 20.f;
#else
    stackView.spacing = 8.f;
#endif
    [view addSubview:stackView];
    
#if TARGET_OS_TV
    static const CGFloat kVerticalMargin = 60.f;
    static const CGFloat kHorizontalMargin = 90.f;
#else
    static const CGFloat kVerticalMargin = 8.f;
    static const CGFloat kHorizontalMargin = 8.f;
#endif

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:view.topAnchor constant:kVerticalMargin],
        [stackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-kVerticalMargin],
        [stackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:kHorizontalMargin],
        [stackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-kHorizontalMargin]
    ]];
    
    UIView *topSpacerView = [self createSpacerViewInStackView:stackView];
    [self createImageViewInStackView:stackView];
    [self createMessageLabelInStackView:stackView];
#if TARGET_OS_IOS
    [self createInstructionsLabelInStackView:stackView];
#endif
    UIView *bottomSpacerView = [self createSpacerViewInStackView:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [topSpacerView.heightAnchor constraintEqualToAnchor:bottomSpacerView.heightAnchor]
    ]];
}

- (void)createImageViewInStackView:(UIStackView *)stackView
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.tintColor = UIColor.whiteColor;
    [stackView addArrangedSubview:imageView];
    self.imageView = imageView;
    
#if TARGET_OS_TV
    static const CGFloat kImageHeight = 100.f;
#else
    static const CGFloat kImageHeight = 25.f;
#endif
    
    [NSLayoutConstraint activateConstraints:@[
        [[imageView.heightAnchor constraintEqualToConstant:kImageHeight] srgletterbox_withPriority:999]
    ]];
}

- (void)createMessageLabelInStackView:(UIStackView *)stackView
{
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.numberOfLines = 3;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:messageLabel];
    self.messageLabel = messageLabel;
}

#if TARGET_OS_IOS

- (void)createInstructionsLabelInStackView:(UIStackView *)stackView
{
    UILabel *instructionsLabel = [[UILabel alloc] init];
    instructionsLabel.numberOfLines = 1;
    instructionsLabel.textColor = [UIColor srg_colorFromHexadecimalString:@"#aaaaaa"];
    instructionsLabel.textAlignment = NSTextAlignmentCenter;
    instructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
    [stackView addArrangedSubview:instructionsLabel];
    self.instructionsLabel = instructionsLabel;
}

#endif

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
#if TARGET_OS_IOS
    self.instructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
#endif
}

- (void)metadataDidChange
{
    [super metadataDidChange];
    
    [self refresh];
}

- (void)playbackDidFail
{
    [super playbackDidFail];
    
    [self refresh];
}

#if TARGET_OS_IOS

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    NSError *error = self.controller.error;
    if (error) {
        self.alpha = (! [error.domain isEqualToString:SRGLetterboxErrorDomain] || error.code != SRGLetterboxErrorCodeNotAvailable) ? 1.f : 0.f;
    }
    else {
        self.alpha = 0.f;
    }
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.imageView.hidden = NO;
    self.messageLabel.hidden = NO;
    
    self.instructionsLabel.hidden = NO;
    self.retryTapGestureRecognizer.enabled = YES;
    
    if (! self.parentLetterboxView.userInterfaceEnabled) {
        self.instructionsLabel.hidden = YES;
        self.retryTapGestureRecognizer.enabled = NO;
    }
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 170.f) {
        self.instructionsLabel.hidden = YES;
    }
    if (height < 140.f) {
        self.messageLabel.hidden = YES;
    }
}

#pragma mark Actions

- (void)retry:(id)sender
{
    [self.controller restart];
}

#endif

#pragma mark UI

- (void)refresh
{
    NSError *error = self.controller.error;
    if (error) {
        self.imageView.image = [UIImage srg_letterboxImageForError:error];
        self.messageLabel.text = error.localizedDescription;
#if TARGET_OS_IOS
        self.instructionsLabel.text = (error != nil) ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
#endif
    }
#if TARGET_OS_TV
    else if (! self.controller.URN) {
        self.imageView.image = [UIImage srg_letterboxImageNamed:@"generic_error"];
        self.messageLabel.text = SRGLetterboxLocalizedString(@"No content", @"Message displayed when no content is being played");
    }
#endif
    else {
        self.imageView.image = nil;
        self.messageLabel.text = nil;
#if TARGET_OS_IOS
        self.instructionsLabel.text = nil;
#endif
    }
}

@end
