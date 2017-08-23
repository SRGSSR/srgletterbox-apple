//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGMedia+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@implementation UILabel (SRGLetterbox)

#pragma mark Public

- (void)play_displayDurationLabelForLive
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"LIVE", @"Short name to explain that a content is a live media. Display on the thumbnail in uppercase.")].uppercaseString
                                                                                       attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                                     NSForegroundColorAttributeName : [UIColor whiteColor] }];
    
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"●  ")
                                                                           attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                         NSForegroundColorAttributeName : [UIColor redColor] }]];
    
    self.attributedText = attributedText.copy;
    self.hidden = NO;
}

- (void)srg_displayAvailabilityLabelForMedia:(SRGMedia *)media
{
    self.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    if (media.srg_availability == SRGMediaAvailabilityExpired) {
        self.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"EXPIRED", @"Label to explain that a content has expired. Display of the view in uppercase.").uppercaseString];
        self.hidden = NO;
    }
    else if (media.srg_availability == SRGMediaAvailabilitySoon) {
        NSString *availabilityLabelText = SRGLetterboxLocalizedString(@"SOON", @"Label to explain that a content will be available. Display of the view in uppercase.").uppercaseString;
        
        if (media.contentType == SRGContentTypeScheduledLivestream) {
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", availabilityLabelText]
                                                                                               attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                                             NSForegroundColorAttributeName : [UIColor whiteColor] }];
            
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"●  ")
                                                                                   attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                                 NSForegroundColorAttributeName : [UIColor whiteColor] }]];
            
            self.attributedText = attributedText.copy;
        }
        else {
            self.text = [NSString stringWithFormat:@"  %@  ", availabilityLabelText];

        }
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.hidden = YES;
    }
}

@end
