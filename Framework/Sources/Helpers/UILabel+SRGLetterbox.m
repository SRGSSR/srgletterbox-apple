//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"
#import "SRGMedia+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@implementation UILabel (SRGLetterbox)

- (void)srg_displayAvailabilityLabelForMedia:(SRGMedia *)media
{
    self.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    if (media.srg_availability == SRGMediaAvailabilityExpired) {
        self.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"EXPIRED", @"Label to explain that a content has expired. Display of the view in uppercase.").uppercaseString];
        self.hidden = NO;
    }
    else if (media.srg_availability == SRGMediaAvailabilitySoon) {
        NSString *availabilityLabelText = nil;
        NSTimeInterval intervalToStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        
        if (intervalToStart > 60.f * 60.f) {
            static NSDateComponentsFormatter *s_dropLeadingDateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dropLeadingDateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dropLeadingDateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;
                s_dropLeadingDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad | NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
            });
            availabilityLabelText = [s_dropLeadingDateComponentsFormatter stringFromTimeInterval:intervalToStart];
        }
        else {
            static NSDateComponentsFormatter *s_padDateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_padDateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_padDateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour;
                s_padDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
            });
            availabilityLabelText = [s_padDateComponentsFormatter stringFromTimeInterval:intervalToStart];
        }
        
        if (media.contentType == SRGContentTypeLivestream || media.contentType == SRGContentTypeScheduledLivestream) {
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", availabilityLabelText]
                                                                                               attributes:@{ NSFontAttributeName : self.font,
                                                                                                             NSForegroundColorAttributeName : [UIColor whiteColor] }];
            
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"●  ")
                                                                                   attributes:@{ NSFontAttributeName : self.font,
                                                                                                 NSForegroundColorAttributeName : [UIColor whiteColor] }]];
            
            self.attributedText = attributedText.copy;
        }
        else {
            self.text = [NSString stringWithFormat:@"  %@  ", availabilityLabelText];

        }
        
        self.accessibilityLabel = [[NSDateFormatter srg_relativeDateAndTimeAccessibilityFormatter] stringFromDate:media.date];
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.accessibilityLabel = nil;
        self.hidden = YES;
    }
}

@end
