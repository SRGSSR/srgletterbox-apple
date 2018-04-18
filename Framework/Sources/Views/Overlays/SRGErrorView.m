//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGErrorView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxView+Private.h"
#import "SRGStackView.h"
#import "UIImage+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGErrorView ()

@property (nonatomic, weak) IBOutlet SRGStackView *stackView;

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UILabel *messageLabel;
@property (nonatomic, weak) UILabel *instructionsLabel;

@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *retryTapGestureRecognizer;

@end

@implementation SRGErrorView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.messageLabel.numberOfLines = 3;
    self.instructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
    
    self.stackView.spacing = 8.f;
    
    UIView *spacerView1 = [[UIView alloc] init];
    [self.stackView addSubview:spacerView1];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.tintColor = UIColor.whiteColor;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.stackView addSubview:imageView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 255;
    }];
    self.imageView = imageView;
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.numberOfLines = 1;
    [self.stackView addSubview:messageLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 255;
    }];
    self.messageLabel = messageLabel;
    
    UILabel *instructionsLabel = [[UILabel alloc] init];
    instructionsLabel.textAlignment = NSTextAlignmentCenter;
    instructionsLabel.textColor = UIColor.lightGrayColor;
    instructionsLabel.numberOfLines = 1;
    [self.stackView addSubview:instructionsLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 255;
    }];
    self.instructionsLabel = instructionsLabel;
    
    UIView *spacerView2 = [[UIView alloc] init];
    [self.stackView addSubview:spacerView2];
}

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

#pragma mark UI

- (void)refresh
{
    NSError *error = self.controller.error;
    UIImage *image = [UIImage srg_letterboxImageForError:error];
    self.imageView.image = image;
    self.messageLabel.text = error.localizedDescription;
    self.instructionsLabel.text = (error != nil) ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
}

#pragma mark Actions

- (IBAction)retry:(id)sender
{
    [self.controller restart];
}

@end
