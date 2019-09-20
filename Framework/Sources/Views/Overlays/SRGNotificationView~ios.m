//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGNotificationView.h"

#import "SRGLetterboxBaseView+Subclassing.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGNotificationView ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageLabelTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageLabelBottomConstraint;

@end

@implementation SRGNotificationView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor srg_blueColor];
    
    // Workaround UIImage view tint color bug
    // See http://stackoverflow.com/a/26042893/760435
    UIImage *image = self.iconImageView.image;
    self.iconImageView.image = nil;
    self.iconImageView.image = image;
    self.messageLabel.text = nil;
    self.iconImageView.hidden = YES;
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
    
    CGFloat verticalMargin = hasMessage ? 6.f : 0.f;
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
