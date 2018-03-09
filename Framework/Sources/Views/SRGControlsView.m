//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlsView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxPlaybackButton.h"
#import "SRGLetterboxTimeSlider.h"
#import "SRGLetterboxView+Private.h"
#import "UIFont+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SRGControlsView ()

@property (nonatomic, weak) IBOutlet SRGLetterboxPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *forwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *skipToLiveButton;

@property (nonatomic, weak) IBOutlet UIStackView *controlsStackView;
@property (nonatomic, weak) IBOutlet SRGViewModeButton *viewModeButton;
@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet SRGLetterboxTimeSlider *timeSlider;
@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;

@property (nonatomic, weak) IBOutlet UILabel *durationLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToBackwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToForwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingForwardToSkipToLiveConstraint;

@end

@implementation SRGControlsView

#pragma mark Getters and setters

- (CMTime)time
{
    return self.timeSlider.time;
}

- (NSDate *)date
{
    return self.timeSlider.date;
}

- (BOOL)isLive
{
    return self.timeSlider.live;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backwardSeekButton.alpha = 0.f;
    self.forwardSeekButton.alpha = 0.f;
    self.skipToLiveButton.alpha = 0.f;
    
    self.timeSlider.alpha = 0.f;
    self.timeSlider.resumingAfterSeek = NO;
    self.timeSlider.delegate = self;
    
    self.airplayButton.image = [UIImage imageNamed:@"airplay-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.pictureInPictureButton.startImage = [UIImage imageNamed:@"picture_in_picture_start-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.pictureInPictureButton.stopImage = [UIImage imageNamed:@"picture_in_picture_stop-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.tracksButton.image = [UIImage imageNamed:@"subtitles_off-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.tracksButton.selectedImage = [UIImage imageNamed:@"subtitles_on-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond;
    });
    
    self.backwardSeekButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ backward", @"Seek backward button label with a custom time range"),
                                                  [s_dateComponentsFormatter stringFromTimeInterval:SRGLetterboxBackwardSkipInterval]];
    self.forwardSeekButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ forward", @"Seek forward button label with a custom time range"),
                                                 [s_dateComponentsFormatter stringFromTimeInterval:SRGLetterboxForwardSkipInterval]];
    self.skipToLiveButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Back to live", @"Back to live label");
}

- (void)didUpdateController
{
    [super didUpdateController];
    
    self.playbackButton.controller = self.controller;
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airplayButton.mediaPlayerController = mediaPlayerController;
    self.tracksButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
    self.viewModeButton.mediaPlayerView = mediaPlayerController.view;
}

- (void)reloadData
{
    [super reloadData];
    
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    if (playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStateEnded && playbackState != SRGMediaPlayerPlaybackStatePreparing
            && self.controller.mediaPlayerController.streamType == SRGStreamTypeOnDemand) {
        SRGChapter *mainChapter = self.controller.mediaComposition.mainChapter;
        
        NSTimeInterval durationInSeconds = mainChapter.duration / 1000;
        if (durationInSeconds < 60. * 60) {
            self.durationLabel.text = [[NSDateComponentsFormatter srg_shortDateComponentsFormatter] stringFromTimeInterval:durationInSeconds];
        }
        else {
            self.durationLabel.text = [[NSDateComponentsFormatter srg_mediumDateComponentsFormatter] stringFromTimeInterval:durationInSeconds];
        }
        self.durationLabel.accessibilityLabel = [[NSDateComponentsFormatter srg_accessibilityDateComponentsFormatter] stringFromTimeInterval:durationInSeconds];
    }
    else {
        self.durationLabel.text = nil;
        self.durationLabel.accessibilityLabel = nil;
    }
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // General playback controls
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        self.forwardSeekButton.alpha = 0.f;
        self.backwardSeekButton.alpha = 0.f;
        self.skipToLiveButton.alpha = [self.controller canSkipToLive] ? 1.f : 0.f;
        
        self.timeSlider.alpha = 0.f;
    }
    else {
        self.forwardSeekButton.alpha = [self.controller canSkipForward] ? 1.f : 0.f;
        self.backwardSeekButton.alpha = [self.controller canSkipBackward] ? 1.f : 0.f;
        self.skipToLiveButton.alpha = [self.controller canSkipToLive] ? 1.f : 0.f;
        
        SRGMediaPlayerStreamType streamType = mediaPlayerController.streamType;
        self.timeSlider.alpha = (streamType == SRGMediaPlayerStreamTypeOnDemand || streamType == SRGMediaPlayerStreamTypeDVR) ? 1.f : 0.f;
    }
    
    self.playbackButton.alpha = self.controller.loading ? 0.f : 1.f;
    
    CGFloat width = CGRectGetWidth(self.frame);
    SRGImageSet imageSet = (width < 668.f) ? SRGImageSetNormal : SRGImageSetLarge;
    CGFloat horizontalSpacing = (imageSet == SRGImageSetNormal) ? 0.f : 20.f;
    
    self.horizontalSpacingPlaybackToBackwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingPlaybackToForwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingForwardToSkipToLiveConstraint.constant = horizontalSpacing;
    
    self.playbackButton.imageSet = imageSet;
    
    [self.backwardSeekButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSeekButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:imageSet] forState:UIControlStateNormal];
    
    // Responsiveness
    self.skipToLiveButton.hidden = NO;
    self.timeSlider.hidden = NO;
    self.durationLabel.hidden = NO;
    self.backwardSeekButton.hidden = NO;
    self.forwardSeekButton.hidden = NO;
    self.viewModeButton.alwaysHidden = NO;
    self.pictureInPictureButton.alwaysHidden = NO;
    self.tracksButton.alwaysHidden = YES;
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 165.f) {
        self.skipToLiveButton.hidden = YES;
        self.timeSlider.hidden = YES;
        self.durationLabel.hidden = YES;
    }
    if (height < 120.f) {
        self.backwardSeekButton.hidden = YES;
        self.forwardSeekButton.hidden = YES;
        self.viewModeButton.alwaysHidden = YES;
        self.pictureInPictureButton.alwaysHidden = YES;
        self.tracksButton.alwaysHidden = YES;
    }
    
    if (width < 290.f) {
        self.skipToLiveButton.hidden = YES;
        self.timeSlider.hidden = YES;
        self.durationLabel.hidden = YES;
    }
    if (width < 215.f) {
        self.backwardSeekButton.hidden = YES;
        self.forwardSeekButton.hidden = YES;
        self.viewModeButton.alwaysHidden = YES;
        self.pictureInPictureButton.alwaysHidden = YES;
        self.tracksButton.alwaysHidden = YES;
    }
    
    // Fix incorrect empty space after hiding the full screen button on iOS 9.
    NSOperatingSystemVersion operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    if (operatingSystemVersion.majorVersion == 9) {
        [self.controlsStackView setNeedsLayout];
        [self.controlsStackView layoutIfNeeded];
    }
}

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToPlaybackTime:(CMTime)time withValue:(float)value interactive:(BOOL)interactive
{
    [self.delegate controlsView:self isMovingToPlaybackTime:time withValue:value interactive:interactive];
}

- (NSAttributedString *)timeSlider:(SRGTimeSlider *)slider labelForValue:(float)value time:(CMTime)time
{
    NSDictionary<NSAttributedStringKey, id> *attributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] };
    
    SRGMediaPlayerStreamType streamType = slider.mediaPlayerController.streamType;
    if (slider.isLive) {
        return [[NSAttributedString alloc] initWithString:SRGLetterboxLocalizedString(@"In Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live stream or a timeshift stream in live") attributes:attributes];
    }
    else if (streamType == SRGMediaPlayerStreamTypeDVR) {
        NSDate *date = slider.date;
        if (date) {
            static dispatch_once_t s_onceToken;
            static NSDateFormatter *s_dateFormatter;
            dispatch_once(&s_onceToken, ^{
                s_dateFormatter = [[NSDateFormatter alloc] init];
                s_dateFormatter.dateStyle = NSDateFormatterNoStyle;
                s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
            });
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@" ") attributes:@{ NSFontAttributeName : [UIFont srg_awesomeFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[s_dateFormatter stringFromDate:date] attributes:attributes]];
            return [attributedString copy];
        }
        else {
            return [[NSAttributedString alloc] initWithString:@"--:--" attributes:attributes];
        }
    }
    else if (streamType == SRGMediaPlayerStreamTypeLive) {
        return nil;
    }
    else {
        NSDateComponentsFormatter *dateComponentsFormatter = (fabsf(value) < 60.f * 60.f) ? [NSDateComponentsFormatter srg_shortDateComponentsFormatter] : [NSDateComponentsFormatter srg_mediumDateComponentsFormatter];
        NSString *string = [dateComponentsFormatter stringFromTimeInterval:value];
        return [[NSAttributedString alloc] initWithString:string attributes:attributes];
    }
}

#pragma mark Actions

- (IBAction)skipBackward:(id)sender
{
    [self.controller skipBackwardWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToPlaybackTime:self.timeSlider.time withValue:self.timeSlider.value interactive:YES];
    }];
}

- (IBAction)skipForward:(id)sender
{
    [self.controller skipForwardWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToPlaybackTime:self.timeSlider.time withValue:self.timeSlider.value interactive:YES];
    }];
}

- (IBAction)skipToLive:(id)sender
{
    [self.controller skipToLiveWithCompletionHandler:nil];
}

- (IBAction)hideUserInterface:(id)sender
{
    [self.delegate controlsViewDidTap:self];
}

@end
