//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAvailabilityView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"

#import "SRGCountdownView.h"

@interface SRGAvailabilityView ()

@property (nonatomic, weak) UILabel *messageLabel;
@property (nonatomic, weak) SRGCountdownView *countdownView;

@end

@implementation SRGAvailabilityView

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    // TODO:
}

- (void)metadataDidChange
{
    [super metadataDidChange];
    
    [self refresh];
}

- (void)playbackDidFail
{
    [super playbackDidFail];
    
    [self refresh];
}

#pragma mark UI

- (void)refresh
{
    SRGMedia *media = self.controller.media;
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonStartDate) {
        self.messageLabel.text = nil;
        
        NSDate *targetDate = media.startDate ?: media.date;
        
        // Reset the countdown view if the target date changed
        if (self.countdownView.superview && ! [targetDate isEqual:self.countdownView.targetDate]) {
            [self.countdownView removeFromSuperview];
        }
        
        // Lazily add heavy countdown view when required
        if (! self.countdownView.superview) {
            SRGCountdownView *countdownView = [[SRGCountdownView alloc] initWithTargetDate:targetDate];
            [self insertSubview:countdownView atIndex:0];
            self.countdownView = countdownView;
            
            countdownView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[ [countdownView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                       [countdownView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                                       [countdownView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                                       [countdownView.rightAnchor constraintEqualToAnchor:self.rightAnchor] ]];
        }
    }
    else if (blockingReason == SRGBlockingReasonEndDate) {
        self.messageLabel.text = SRGLetterboxLocalizedString(@"Expired", @"Label to explain that a content has expired");
        [self.countdownView removeFromSuperview];
    }
    else {
        self.messageLabel.text = nil;
        [self.countdownView removeFromSuperview];
    }
}

@end
