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
#import "SRGLetterboxError.h"
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
    
    NSError *error = self.controller.error;
    self.alpha = ([error.domain isEqualToString:SRGLetterboxErrorDomain] && error.code == SRGLetterboxErrorCodeNotAvailable) ? 1.f : 0.f;
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
        self.messageLabel.text = nil;
        self.countdownView.remainingTimeInterval = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
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
        self.messageLabel.hidden = YES;
        self.countdownView.hidden = NO;
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
