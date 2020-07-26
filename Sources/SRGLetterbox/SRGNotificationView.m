//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGNotificationView.h"

#import "UIImage+SRGLetterbox.h"
#import "SRGLetterboxBaseView+Subclassing.h"

#if TARGET_OS_TV
static const CGFloat kImageLength = 24.f;
static const CGFloat kLeadingMargin = 16.f;
static const CGFloat kMargin = 20.f;
#else
static const CGFloat kImageLength = 16.f;
static const CGFloat kLeadingMargin = 4.f;
static const CGFloat kMargin = 6.f;
#endif

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
    messageLabel.numberOfLines = 2;
    [messageLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [contentView addSubview:messageLabel];
    self.messageLabel = messageLabel;
        
    [NSLayoutConstraint activateConstraints:@[
        [iconImageView.widthAnchor constraintEqualToConstant:kImageLength],
        [iconImageView.heightAnchor constraintEqualToAnchor:iconImageView.widthAnchor],
        [iconImageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:kLeadingMargin],
        [iconImageView.centerYAnchor constraintEqualToAnchor:messageLabel.centerYAnchor],
        [messageLabel.leadingAnchor constraintEqualToAnchor:iconImageView.trailingAnchor constant:kMargin],
        [messageLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-kMargin],
        self.messageLabelTopConstraint = [messageLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        self.messageLabelBottomConstraint = [contentView.bottomAnchor constraintEqualToAnchor:messageLabel.bottomAnchor]
    ]];
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
    
    CGFloat verticalMargin = hasMessage ? kMargin : 0.f;
    self.messageLabelTopConstraint.constant = verticalMargin;
    self.messageLabelBottomConstraint.constant = verticalMargin;
    
    // The notification message determines the height of the view required to display it.
    self.messageLabel.text = message;
    
    // Calculate the needed height
    UIFont *font = self.messageLabel.font;
    CGRect boundingRect = [message boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.messageLabel.frame), CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{ NSFontAttributeName : font }
                                                context:nil];
    CGFloat lineHeight = font.lineHeight;
    NSInteger numberOfLines = MIN(CGRectGetHeight(boundingRect) / lineHeight, self.messageLabel.numberOfLines);
    return ceil(numberOfLines * lineHeight + 2 * verticalMargin);
}

@end
