//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGNotificationView.h"

#import "NSLayoutConstraint+SRGLetterboxPrivate.h"
#import "UIImage+SRGLetterbox.h"
#import "SRGLetterboxBaseView+Subclassing.h"

#if TARGET_OS_TV
static const CGFloat kImageLength = 24.f;
static const CGFloat kMargin = 20.f;
#else
static const CGFloat kImageLength = 16.f;
static const CGFloat kMargin = 8.f;
#endif

@import SRGAppearance;

@interface SRGNotificationView ()

@property (nonatomic, weak) UIImageView *iconImageView;
@property (nonatomic, weak) UILabel *messageLabel;

@end

@implementation SRGNotificationView

#pragma mark Layout

- (void)layoutContentView
{
    [super layoutContentView];
    
    self.contentView.backgroundColor = UIColor.srg_blueColor;
    
    UIView *notificationView = [[UIView alloc] init];
    notificationView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:notificationView];
    
    [NSLayoutConstraint activateConstraints:@[
        [notificationView.leadingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.leadingAnchor],
        [notificationView.trailingAnchor constraintEqualToAnchor:self.contentView.safeAreaLayoutGuide.trailingAnchor],
        [notificationView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [notificationView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
    
    UIImage *iconImage = [UIImage srg_letterboxImageNamed:@"notification"];
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    iconImageView.tintColor = UIColor.whiteColor;
    iconImageView.hidden = YES;
    [notificationView addSubview:iconImageView];
    self.iconImageView = iconImageView;
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.numberOfLines = 2;
    [messageLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [notificationView addSubview:messageLabel];
    self.messageLabel = messageLabel;
        
    [NSLayoutConstraint activateConstraints:@[
        [[iconImageView.widthAnchor constraintEqualToConstant:kImageLength] srgletterbox_withPriority:999],
        [iconImageView.heightAnchor constraintEqualToAnchor:iconImageView.widthAnchor],
        [[iconImageView.leadingAnchor constraintEqualToAnchor:notificationView.leadingAnchor constant:kMargin] srgletterbox_withPriority:999],
        [iconImageView.centerYAnchor constraintEqualToAnchor:messageLabel.centerYAnchor],
        [messageLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [[messageLabel.leadingAnchor constraintEqualToAnchor:iconImageView.trailingAnchor constant:kMargin] srgletterbox_withPriority:999],
        [[messageLabel.trailingAnchor constraintEqualToAnchor:notificationView.trailingAnchor constant:-kMargin] srgletterbox_withPriority:999]
    ]];
}

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.messageLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
}

#pragma mark Refresh

- (CGSize)updateLayoutWithMessage:(NSString *)message width:(CGFloat)width
{
    BOOL hasMessage = (message != nil);
    
    self.iconImageView.hidden = ! hasMessage;
    self.messageLabel.text = message;
    
    if (! hasMessage) {
        return CGSizeZero;
    }
    
    // Calculate the needed height. Remove the width corresponding to non-text items to calculate the required text
    // height
    CGFloat layoutFixedWidth = kImageLength + 3 * kMargin;
    CGFloat availableWidth = fmaxf(width - layoutFixedWidth, 0.f);
    UIFont *font = self.messageLabel.font;
    CGRect boundingRect = [message boundingRectWithSize:CGSizeMake(availableWidth, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{ NSFontAttributeName : font }
                                                context:nil];
    CGFloat lineHeight = font.lineHeight;
    NSInteger numberOfLines = MIN(CGRectGetHeight(boundingRect) / lineHeight, self.messageLabel.numberOfLines);
    if (numberOfLines < 2) {
        return CGSizeMake(ceil(CGRectGetWidth(boundingRect)) + layoutFixedWidth, CGRectGetHeight(boundingRect) + 2 * kMargin);
    }
    else {
        return CGSizeMake(width, ceil(numberOfLines * lineHeight + 2 * kMargin));
    }
}

@end
