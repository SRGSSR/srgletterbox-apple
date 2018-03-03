//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuousPlaybackView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
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

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SRGContinuousPlaybackView

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    SRGLetterboxController *previousController = super.controller;
    
    if (previousController) {
        [previousController removeObserver:self keyPath:@keypath(previousController.continuousPlaybackUpcomingMedia)];
    }
    
    super.controller = controller;
    
    if (controller) {
        @weakify(self)
        @weakify(controller)
        [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            @strongify(controller)
            [self reloadDataForController:controller];
        }];
    }
    
    [self reloadDataForController:controller];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.introLabel.text = SRGLetterboxLocalizedString(@"Next", @"For continuous playback, introductory label for content which is about to start");
    [self.cancelButton setTitle:SRGLetterboxLocalizedString(@"Cancel", @"Title of a cancel button") forState:UIControlStateNormal];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL introLabelHidden = NO;
    BOOL titleLabelHidden = NO;
    BOOL subtitleLabelHidden = NO;
    BOOL cancelButtonHidden = NO;
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 200.f) {
        introLabelHidden = YES;
        subtitleLabelHidden = YES;
    }
    if (height < 150.f) {
        cancelButtonHidden = YES;
    }
    if (height < 100.f) {
        titleLabelHidden = YES;
    }
    
    self.introLabel.hidden = introLabelHidden;
    self.titleLabel.hidden = titleLabelHidden;
    self.subtitleLabel.hidden = subtitleLabelHidden;
    self.cancelButton.hidden = cancelButtonHidden;
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.introLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.titleLabel.font = [UIFont srg_boldFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.cancelButton.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)reloadDataForController:(SRGLetterboxController *)controller
{
    [super reloadDataForController:controller];
    
    // Only update with valid upcoming information
    SRGMedia *upcomingMedia = controller.continuousPlaybackUpcomingMedia;
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
    
    NSTimeInterval duration = [controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:controller.continuousPlaybackTransitionStartDate];
    float progress = (duration != 0) ? ([NSDate.date timeIntervalSinceDate:controller.continuousPlaybackTransitionStartDate]) / duration : 1.f;
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
