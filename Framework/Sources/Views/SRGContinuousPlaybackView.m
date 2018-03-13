//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuousPlaybackView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGRemainingTimeButton.h"
#import "UIImageView+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SRGContinuousPlaybackView ()

@property (nonatomic, weak) IBOutlet UILabel *introLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet SRGRemainingTimeButton *remainingTimeButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@end

@implementation SRGContinuousPlaybackView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.introLabel.text = SRGLetterboxLocalizedString(@"Next", @"For continuous playback, introductory label for content which is about to start");
    [self.cancelButton setTitle:SRGLetterboxLocalizedString(@"Cancel", @"Title of a cancel button") forState:UIControlStateNormal];
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.introLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.titleLabel.font = [UIFont srg_boldFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.cancelButton.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGLetterboxController *controller = self.controller;
    [controller removeObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia)];
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    SRGLetterboxController *controller = self.controller;
    
    @weakify(self)
    [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self refresh];
    }];
    
    [self refresh];
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.introLabel.hidden = NO;
    self.titleLabel.hidden = NO;
    self.subtitleLabel.hidden = NO;
    self.cancelButton.hidden = NO;
    
    if (self.controller.continuousPlaybackUpcomingMedia) {
        self.alpha = 1.f;
        
        CGFloat height = CGRectGetHeight(self.frame);
        if (height < 200.f) {
            self.introLabel.hidden = YES;
            self.subtitleLabel.hidden = YES;
        }
        if (height < 150.f) {
            self.cancelButton.hidden = YES;
        }
        if (height < 100.f) {
            self.titleLabel.hidden = YES;
        }
    }
    else {
        self.alpha = 0.f;
    }
}

#pragma mark UI

- (void)refresh
{
    // Only update with valid upcoming information
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    if (! upcomingMedia) {
        return;
    }
    
    self.titleLabel.text = upcomingMedia.title;
    self.subtitleLabel.text = upcomingMedia.lead ?: upcomingMedia.summary;
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    
    [self.imageView srg_requestImageForObject:upcomingMedia withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
    
    NSTimeInterval duration = [self.controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate];
    float progress = (duration != 0) ? ([NSDate.date timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate]) / duration : 1.f;
    [self.remainingTimeButton setProgress:progress withDuration:duration];
}

#pragma mark Actions

- (IBAction)cancelContinuousPlayback:(id)sender
{
    // Save media informations since cancelling will change it
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    [self.controller cancelContinuousPlayback];
    [self.delegate continuousPlaybackView:self didCancelWithUpcomingMedia:upcomingMedia];
}

- (IBAction)playUpcomingMedia:(id)sender
{
    // Save media information since playing will change it
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    if ([self.controller playUpcomingMedia]) {
        [self.delegate continuousPlaybackView:self didEngageWithUpcomingMedia:upcomingMedia];
    }
}

@end
