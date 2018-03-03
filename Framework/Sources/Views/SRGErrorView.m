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

@property (nonatomic, weak) IBOutlet UIImageView *errorImageView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;
@property (nonatomic, weak) IBOutlet UILabel *errorInstructionsLabel;

@end

@implementation SRGErrorView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.errorImageView.image = nil;
    self.errorImageView.hidden = YES;
    
    self.errorInstructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Error view layout depends on the view size
    self.errorImageView.hidden = NO;
    self.errorInstructionsLabel.hidden = NO;
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 170.f) {
        self.errorInstructionsLabel.hidden = YES;
    }
    if (height < 140.f) {
        self.errorImageView.hidden = YES;
    }
}

- (void)updateFonts
{
    self.errorLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.errorInstructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)updateForController:(SRGLetterboxController *)controller
{
    // TODO: Centering issues
    self.errorInstructionsLabel.text = controller.URN ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
    
    // TODO
#if 0
    NSError *error = [self errorForController:controller];
    
    UIImage *image = [UIImage srg_letterboxImageForError:error];
    self.errorImageView.image = image;
    self.errorImageView.hidden = (image == nil);            // Hidden so that the stack view wrapper can adjust its layout properly
    
    self.errorLabel.text = error.localizedDescription;
#endif
}

@end
