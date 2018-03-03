//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAvailabilityView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "SRGCountdownView.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGAvailabilityView ()

@property (nonatomic, weak) IBOutlet SRGCountdownView *countdownView;
@property (nonatomic, weak) IBOutlet UIView *messageBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;

@end

@implementation SRGAvailabilityView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.messageBackgroundView.layer.cornerRadius = 4.f;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // The availability component layout depends on the view size.
    [self reloadDataForController:self.controller];
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];

    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

- (void)reloadDataForController:(SRGLetterboxController *)controller
{
    [super reloadDataForController:controller];
    
    SRGMedia *media = controller.media;
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonEndDate) {
        self.messageLabel.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"Expired", @"Label to explain that a content has expired")];
        self.messageLabel.hidden = NO;
        self.messageBackgroundView.hidden = NO;
        
        self.countdownView.hidden = YES;
    }
    else if (blockingReason == SRGBlockingReasonStartDate) {
        NSTimeInterval timeIntervalBeforeStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(timeIntervalBeforeStart);
        
        // Large number of days. Label only
        if (dateComponents.day >= SRGCountdownViewDaysLimit) {
            static NSDateComponentsFormatter *s_dateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
                s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
            });
            
            self.messageLabel.text = [NSString stringWithFormat:@"  %@  ", [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_dateComponentsFormatter stringFromTimeInterval:timeIntervalBeforeStart]]];
            self.messageLabel.hidden = NO;
            self.messageBackgroundView.hidden = NO;
            
            self.countdownView.hidden = YES;
        }
        // Tiny layout
        else if (CGRectGetWidth(self.frame) < 290.f) {
            NSString *availabilityLabelText = nil;
            if (dateComponents.day > 0) {
                availabilityLabelText = [[NSDateComponentsFormatter srg_longDateComponentsFormatter] stringFromDateComponents:dateComponents];
            }
            else if (timeIntervalBeforeStart >= 60. * 60.) {
                availabilityLabelText = [[NSDateComponentsFormatter srg_mediumDateComponentsFormatter] stringFromDateComponents:dateComponents];
            }
            else if (timeIntervalBeforeStart >= 0) {
                availabilityLabelText = [[NSDateComponentsFormatter srg_shortDateComponentsFormatter] stringFromDateComponents:dateComponents];
            }
            else {
                availabilityLabelText = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
            }
            
            self.messageLabel.hidden = NO;
            self.messageLabel.text = [NSString stringWithFormat:@"  %@  ", availabilityLabelText];
            self.messageBackgroundView.hidden = NO;
            
            self.countdownView.hidden = YES;
        }
        // Large layout
        else {
            self.messageLabel.hidden = YES;
            self.messageBackgroundView.hidden = YES;
            
            self.countdownView.remainingTimeInterval = timeIntervalBeforeStart;
            self.countdownView.hidden = NO;
        }
    }
    else {
        self.messageLabel.hidden = YES;
        self.messageBackgroundView.hidden = YES;
        
        self.countdownView.hidden = YES;
    }
}

@end
