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
#import "UIImage+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>
#import <SRGContentProtection/SRGContentProtection.h>

static NSURL *SRGErrorViewInformationURLForError(NSError *error)
{
    if ([error.domain isEqualToString:SRGContentProtectionErrorDomain] && error.code == SRGContentProtectionErrorUnauthorized) {
        return SRGLetterboxContentProtectionInformationURL();
    }
    else {
        return nil;
    }
}

@interface SRGErrorView ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet UILabel *instructionsLabel;

@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *retryTapGestureRecognizer;

@end

@implementation SRGErrorView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.messageLabel.numberOfLines = 3;
    self.instructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
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
    
    if (SRGErrorViewInformationURLForError(error)) {
        self.instructionsLabel.text = SRGLetterboxLocalizedString(@"Learn more", @"Message displayed when the user has a way to access more information about an error");
    }
    else if (error) {
        self.instructionsLabel.text = SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the user is able to retry");
    }
    else {
        self.instructionsLabel.text = nil;
    }
}

#pragma mark Actions

- (IBAction)didTap:(id)sender
{
    NSError *error = self.controller.error;
    
    NSURL *informationURL = SRGErrorViewInformationURLForError(error);
    if (informationURL) {
        [UIApplication.sharedApplication openURL:informationURL];
    }
    else if (error) {
        [self.controller restart];
    }
}

@end
