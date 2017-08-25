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

- (void)srg_displayAvailabilityLabelForMedia:(SRGMedia *)media
{
    self.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    if (media.srg_availability == SRGMediaAvailabilityExpired) {
        self.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"EXPIRED", @"Label to explain that a content has expired. Display of the view in uppercase.").uppercaseString];
        self.accessibilityLabel = SRGMessageForBlockedMediaWithBlockingReason(SRGBlockingReasonEndDate);
        self.hidden = NO;
    }
    else if (media.srg_availability == SRGMediaAvailabilityNotYet) {
        NSTimeInterval intervalToStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        
        NSString *availabilityLabelText = nil;
        if (intervalToStart > 60. * 60.) {
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
        
        static NSDateComponentsFormatter *s_accessibilityDateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_accessibilityDateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_accessibilityDateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;
            s_accessibilityDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
            s_accessibilityDateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        self.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"This media will be available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_accessibilityDateComponentsFormatter stringFromTimeInterval:intervalToStart]];
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.accessibilityLabel = nil;
        self.hidden = YES;
    }
}

@end
