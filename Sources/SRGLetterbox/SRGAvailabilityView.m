//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAvailabilityView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "SRGCountdownView.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxError.h"
#import "SRGPaddedLabel.h"

@import libextobjc;
@import SRGAppearance;

@interface SRGAvailabilityView ()

@property (nonatomic, weak) SRGCountdownView *countdownView;
@property (nonatomic, weak) SRGPaddedLabel *messageLabel;

@end

@implementation SRGAvailabilityView

#pragma mark Layout

- (void)layoutContentView
{
    [super layoutContentView];
    
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
        
    SRGPaddedLabel *messageLabel = [[SRGPaddedLabel alloc] init];
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.adjustsFontSizeToFitWidth = YES;
    messageLabel.minimumScaleFactor = 0.6f;
    messageLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.75f];
    messageLabel.layer.masksToBounds = YES;
#if TARGET_OS_TV
    messageLabel.horizontalMargin = 30.f;
    messageLabel.verticalMargin = 12.f;
    messageLabel.layer.cornerRadius = 6.f;
#else
    messageLabel.horizontalMargin = 15.f;
    messageLabel.verticalMargin = 9.f;
    messageLabel.layer.cornerRadius = 3.f;
#endif
    [self.contentView addSubview:messageLabel];
    self.messageLabel = messageLabel;
    
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [messageLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [messageLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:8.f],
        [messageLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:8.f],
        [messageLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
}

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.messageLabel.font = [SRGFont fontWithStyle:SRGFontStyleH4];
}

- (void)metadataDidChange
{
    [super metadataDidChange];
    
    [self refresh];
    [self updateLayout];
}

#if TARGET_OS_IOS

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden transientState:(SRGLetterboxViewTransientState)transientState
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden transientState:transientState];
    
    NSError *error = self.controller.error;
    self.alpha = ([error.domain isEqualToString:SRGLetterboxErrorDomain] && error.code == SRGLetterboxErrorCodeNotAvailable) ? 1.f : 0.f;
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden transientState:(SRGLetterboxViewTransientState)transientState
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden transientState:transientState];
    
    [self updateLayout];
}

#endif

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
            SRGCountdownView *countdownView = [[SRGCountdownView alloc] initWithTargetDate:targetDate frame:CGRectZero];
            [self.contentView addSubview:countdownView];
            self.countdownView = countdownView;
            
            countdownView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[ [countdownView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
                                                       [countdownView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
                                                       [countdownView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
                                                       [countdownView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor]
            ]];
        }
    }
    else if (blockingReason == SRGBlockingReasonEndDate) {
        self.messageLabel.text = SRGLetterboxLocalizedString(@"Expired", @"Label to explain that a content has expired").uppercaseString;
        [self.countdownView removeFromSuperview];
    }
    else {
        self.messageLabel.text = nil;
        [self.countdownView removeFromSuperview];
    }
}

- (void)updateLayout
{
    SRGMedia *media = self.controller.media;
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonStartDate) {
        self.messageLabel.hidden = YES;
    }
    else if (blockingReason == SRGBlockingReasonEndDate) {
        self.messageLabel.hidden = NO;
    }
    else {
        self.messageLabel.hidden = YES;
    }
}

@end
