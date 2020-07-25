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
@property (nonatomic, weak) UILabel *instructionsLabel;

@property (nonatomic, weak) UITapGestureRecognizer *retryTapGestureRecognizer;

@end

@implementation SRGErrorView

#pragma mark Layout

- (void)createView
{
    [super createView];
    
#if TARGET_OS_TV
    // TODO
#else
    self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
    
    UITapGestureRecognizer *retryTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retry:)];
    [self addGestureRecognizer:retryTapGestureRecognizer];
    self.retryTapGestureRecognizer = retryTapGestureRecognizer;
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.spacing = 8.f;
    [self addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8.f],
        [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8.f],
        [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8.f],
        [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8.f]
    ]];
    
    UIView *topSpacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:topSpacerView];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.tintColor = UIColor.whiteColor;
    [stackView addArrangedSubview:imageView];
    self.imageView = imageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [[imageView.heightAnchor constraintEqualToConstant:25.f] srgletterbox_withPriority:999]
    ]];
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.numberOfLines = 3;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addArrangedSubview:messageLabel];
    self.messageLabel = messageLabel;
    
    UILabel *instructionsLabel = [[UILabel alloc] init];
    instructionsLabel.numberOfLines = 1;
    instructionsLabel.textColor = [UIColor srg_colorFromHexadecimalString:@"#aaaaaa"];
    instructionsLabel.textAlignment = NSTextAlignmentCenter;
    instructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
    [stackView addArrangedSubview:instructionsLabel];
    self.instructionsLabel = instructionsLabel;
    
    UIView *bottomSpacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:bottomSpacerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [topSpacerView.heightAnchor constraintEqualToAnchor:bottomSpacerView.heightAnchor]
    ]];
#endif
}

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.instructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
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

#endif

#pragma mark UI

- (void)refresh
{
    NSError *error = self.controller.error;
    if (error) {
        self.imageView.image = [UIImage srg_letterboxImageForError:error];
        self.messageLabel.text = error.localizedDescription;
        self.instructionsLabel.text = (error != nil) ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
    }
#if TARGET_OS_TV
    else if (! self.controller.URN) {
        self.imageView.image = [UIImage srg_letterboxImageNamed:@"generic_error"];
        self.messageLabel.text = SRGLetterboxLocalizedString(@"No content", @"Message displayed when no content is being played");
        self.instructionsLabel.text = nil;
    }
#endif
    else {
        self.imageView.image = nil;
        self.messageLabel.text = nil;
        self.instructionsLabel.text = nil;
    }
}

#pragma mark Actions

- (void)retry:(id)sender
{
    [self.controller restart];
}

@end
