//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGErrorView.h"

#import "NSBundle+SRGLetterbox.h"
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
    
    self.instructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateForController:self.controller];
}

- (void)updateForContentSizeCategory
{
    [super updateForContentSizeCategory];
    
    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.instructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)updateForController:(SRGLetterboxController *)controller
{
    [super updateForController:controller];
    
    // TODO: Centering issues
    self.instructionsLabel.text = controller.URN ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
    
    // TODO: Warning, image view visibility depends on both layout size and image availability
#if 0
    NSError *error = [self errorForController:controller];
    
    UIImage *image = [UIImage srg_letterboxImageForError:error];
    self.errorImageView.image = image;
    self.errorImageView.hidden = (image == nil);            // Hidden so that the stack view wrapper can adjust its layout properly
    
    self.errorLabel.text = error.localizedDescription;
#endif
    
    self.imageView.hidden = NO;
    self.instructionsLabel.hidden = NO;
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 170.f) {
        self.instructionsLabel.hidden = YES;
    }
    if (height < 140.f) {
        self.imageView.hidden = YES;
    }
}

@end
