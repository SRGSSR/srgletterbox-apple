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

@interface SRGErrorView ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet UILabel *instructionsLabel;

@property (nonatomic, weak) UITapGestureRecognizer *retryTapGestureRecognizer;

@end

@implementation SRGErrorView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.messageLabel.numberOfLines = 3;
    
    self.instructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
    
    UITapGestureRecognizer *retryTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retry:)];
    [self addGestureRecognizer:retryTapGestureRecognizer];
    self.retryTapGestureRecognizer = retryTapGestureRecognizer;
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
