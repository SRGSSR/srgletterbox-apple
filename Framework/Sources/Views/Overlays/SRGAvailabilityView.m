//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAvailabilityView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGCountdownView.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGPaddedLabel.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SRGAvailabilityView ()

@property (nonatomic, weak) IBOutlet SRGCountdownView *countdownView;
@property (nonatomic, weak) IBOutlet SRGPaddedLabel *messageLabel;

@end

@implementation SRGAvailabilityView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.messageLabel.horizontalMargin = 5.f;
    self.messageLabel.verticalMargin = 2.f;
    self.messageLabel.layer.cornerRadius = 4.f;
    self.messageLabel.layer.masksToBounds = YES;
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];

    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
}

- (void)metadataDidChange
{
    [super metadataDidChange];
    
    [self refresh];
    [self updateLayout];
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    SRGMedia *media = self.controller.media;
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    self.alpha = (blockingReason == SRGBlockingReasonStartDate || blockingReason == SRGBlockingReasonEndDate) ? 1.f : 0.f;
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    [self updateLayout];
}

#pragma mark UI

- (void)refresh
{
    SRGMedia *media = self.controller.media;
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonStartDate) {
        NSTimeInterval timeIntervalBeforeStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(timeIntervalBeforeStart);
        
        if (dateComponents.day >= SRGCountdownViewDaysLimit) {
            static NSDateComponentsFormatter *s_dateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
                s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
            });
            self.messageLabel.text = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_dateComponentsFormatter stringFromTimeInterval:timeIntervalBeforeStart]];
        }
        else if (dateComponents.day > 0) {
            self.messageLabel.text = [[NSDateComponentsFormatter srg_longDateComponentsFormatter] stringFromDateComponents:dateComponents];
        }
        else if (timeIntervalBeforeStart >= 60. * 60.) {
            self.messageLabel.text = [[NSDateComponentsFormatter srg_mediumDateComponentsFormatter] stringFromDateComponents:dateComponents];
        }
        else if (timeIntervalBeforeStart >= 0.) {
            self.messageLabel.text = [[NSDateComponentsFormatter srg_shortDateComponentsFormatter] stringFromDateComponents:dateComponents];
        }
        else {
            self.messageLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
        }
        
        self.countdownView.remainingTimeInterval = timeIntervalBeforeStart;
    }
    else if (blockingReason == SRGBlockingReasonEndDate) {
        self.messageLabel.text = SRGLetterboxLocalizedString(@"Expired", @"Label to explain that a content has expired");
        self.countdownView.remainingTimeInterval = 0.;
    }
    else {
        self.messageLabel.text = nil;
        self.countdownView.remainingTimeInterval = 0.;
    }
}

- (void)updateLayout
{
    SRGMedia *media = self.controller.media;
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonStartDate) {
        NSTimeInterval timeIntervalBeforeStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(timeIntervalBeforeStart);
        
        if (dateComponents.day >= SRGCountdownViewDaysLimit) {
            self.messageLabel.hidden = NO;
            self.countdownView.hidden = YES;
        }
        else if (CGRectGetWidth(self.frame) < 290.f) {
            self.messageLabel.hidden = NO;
            self.countdownView.hidden = YES;
        }
        else {
            self.messageLabel.hidden = YES;
            self.countdownView.hidden = NO;
        }
    }
    else if (blockingReason == SRGBlockingReasonEndDate) {
        self.messageLabel.hidden = NO;
        self.countdownView.hidden = YES;
    }
    else {
        self.messageLabel.hidden = YES;
        self.countdownView.hidden = YES;
    }
}

@end
