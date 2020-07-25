//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGNotificationView.h"

#import "UIImage+SRGLetterbox.h"
#import "SRGLetterboxBaseView+Subclassing.h"

@import SRGAppearance;

@interface SRGNotificationView ()

@property (nonatomic, weak) UIImageView *iconImageView;
@property (nonatomic, weak) UILabel *messageLabel;

@property (nonatomic, weak) NSLayoutConstraint *messageLabelTopConstraint;
@property (nonatomic, weak) NSLayoutConstraint *messageLabelBottomConstraint;

@end

@implementation SRGNotificationView

#pragma mark Layout

- (void)createView
{
    [super createView];
    
    self.backgroundColor = UIColor.srg_blueColor;
    
#if TARGET_OS_TV
    // TODO:
    
#else
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:contentView];
    
    if (@available(iOS 11, *)) {
        [NSLayoutConstraint activateConstraints:@[
            [contentView.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor],
            [contentView.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor]
        ]];
    }
    else {
        [NSLayoutConstraint activateConstraints:@[
            [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
        ]];
    }
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    UIImage *iconImage = [UIImage srg_letterboxImageNamed:@"notification"];
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    iconImageView.tintColor = UIColor.whiteColor;
    iconImageView.hidden = YES;
    [contentView addSubview:iconImageView];
    self.iconImageView = iconImageView;
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.numberOfLines = 0;
    [messageLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [contentView addSubview:messageLabel];
    self.messageLabel = messageLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [iconImageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:4.f],
        [iconImageView.centerYAnchor constraintEqualToAnchor:messageLabel.centerYAnchor],
        [messageLabel.leadingAnchor constraintEqualToAnchor:iconImageView.trailingAnchor constant:8.f],
        [messageLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-8.f],
        self.messageLabelTopConstraint = [messageLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        self.messageLabelBottomConstraint = [contentView.bottomAnchor constraintEqualToAnchor:messageLabel.bottomAnchor]
    ]];
#endif
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

#pragma mark Refresh

- (CGFloat)updateLayoutWithMessage:(NSString *)message
{
    BOOL hasMessage = (message != nil);
    
    self.iconImageView.hidden = ! hasMessage;
    
#if TARGET_OS_TV
    CGFloat verticalMargin = hasMessage ? 20.f : 0.f;
#else
    CGFloat verticalMargin = hasMessage ? 6.f : 0.f;
#endif
    self.messageLabelTopConstraint.constant = verticalMargin;
    self.messageLabelBottomConstraint.constant = verticalMargin;
    
    // The notification message determines the height of the view required to display it.
    self.messageLabel.text = message;
    
    // Force autolayout
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // Return the minimum size which satisfies the constraints. Put a strong requirement on width and properly let the height
    // adjusts
    // For an explanation, see http://titus.io/2015/01/13/a-better-way-to-autosize-in-ios-8.html
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.width = CGRectGetWidth(self.frame);
    return [self systemLayoutSizeFittingSize:fittingSize
               withHorizontalFittingPriority:UILayoutPriorityRequired
                     verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
}

@end
