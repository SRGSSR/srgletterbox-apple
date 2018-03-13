//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGErrorView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxView+Private.h"
#import "UIImage+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGErrorView ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet UILabel *instructionsLabel;

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

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SRGLetterboxPlaybackDidRetryNotification
                                                  object:self.controller];
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackDidRetry:)
                                                 name:SRGLetterboxPlaybackDidRetryNotification
                                               object:self.controller];

}

- (void)playbackDidFail
{
    [super playbackDidFail];
    
    NSError *error = self.contextView.error;
    UIImage *image = [UIImage srg_letterboxImageForError:error];
    self.imageView.image = image;
    self.messageLabel.text = error.localizedDescription;
    self.instructionsLabel.text = (error != nil) ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    if (! self.contextView.error) {
        self.alpha = 0.f;
    }
    else {
        self.alpha = 1.f;
        
        self.imageView.hidden = NO;
        self.messageLabel.hidden = NO;
        self.instructionsLabel.hidden = NO;
        
        CGFloat height = CGRectGetHeight(self.frame);
        if (height < 170.f) {
            self.instructionsLabel.hidden = YES;
        }
        if (height < 140.f) {
            self.messageLabel.hidden = YES;
        }
    }
}

#pragma mark Actions

- (IBAction)retry:(id)sender
{
    [self.controller restart];
}

#pragma mark Notifications

- (void)playbackDidRetry:(NSNotification *)notification
{
    [self setNeedsLayoutAnimated:YES];
}

@end
