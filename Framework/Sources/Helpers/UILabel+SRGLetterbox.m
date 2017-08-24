//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"
#import "NSString+SRGLetterbox.h"
#import "SRGMedia+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@implementation UILabel (SRGLetterbox)

- (void)srg_displayAvailabilityLabelForMedia:(SRGMedia *)media
{
    self.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    if (media.srg_availability == SRGMediaAvailabilityExpired) {
        self.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"EXPIRED", @"Label to explain that a content has expired. Display of the view in uppercase.").uppercaseString];
        self.hidden = NO;
    }
    else if (media.srg_availability == SRGMediaAvailabilitySoon) {
        NSString *availabilityLabelText = [[NSDateFormatter srg_relativeDateAndTimeFormatter] stringFromDate:media.date].srg_localizedUppercaseFirstLetterString;
        NSString *availabilityAccessibilityLabelText = [[NSDateFormatter srg_relativeDateAndTimeAccessibilityFormatter] stringFromDate:media.date];
        
        if (media.srg_today) {
            static NSDateComponentsFormatter *s_dateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour;
                s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
            });
            availabilityLabelText = [s_dateComponentsFormatter stringFromDate:media.startDate toDate:NSDate.date];
        }
        
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
        self.accessibilityLabel = availabilityAccessibilityLabelText;
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.accessibilityLabel = nil;
        self.hidden = YES;
    }
}

@end
