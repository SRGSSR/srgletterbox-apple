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
#import "UIFont+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SRGControlsView ()

@property (nonatomic, weak) IBOutlet SRGLetterboxPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *forwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *skipToLiveButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToBackwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToForwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingForwardToSkipToLiveConstraint;

@property (nonatomic, weak) IBOutlet UIStackView *controlsStackView;
@property (nonatomic, weak) IBOutlet SRGViewModeButton *viewModeButton;
@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet SRGLetterboxTimeSlider *timeSlider;
@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;

@property (nonatomic, weak) IBOutlet UILabel *durationLabel;

@end

@implementation SRGControlsView

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    _controller = controller;
    
    self.playbackButton.controller = controller;
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airplayButton.mediaPlayerController = mediaPlayerController;
    self.tracksButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
    self.viewModeButton.mediaPlayerView = mediaPlayerController.view;
}

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
    self.timeSlider.timeLeftValueLabel.hidden = YES;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Fix incorrect empty space after hiding full screen button on iOS 9.
    NSOperatingSystemVersion operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    if (operatingSystemVersion.majorVersion == 9) {
        [self.controlsStackView setNeedsLayout];
        [self.controlsStackView layoutIfNeeded];
    }
    
    SRGImageSet imageSet = (CGRectGetWidth(self.bounds) < 668.f) ? SRGImageSetNormal : SRGImageSetLarge;
    CGFloat horizontalSpacing = (imageSet == SRGImageSetNormal) ? 0.f : 20.f;
    
    self.horizontalSpacingPlaybackToBackwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingPlaybackToForwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingForwardToSkipToLiveConstraint.constant = horizontalSpacing;
    
    self.playbackButton.imageSet = imageSet;
    
    [self.backwardSeekButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSeekButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:imageSet] forState:UIControlStateNormal];
    
    // Control visibility depends on the view size.
    BOOL backwardSeekButtonHidden = NO;
    BOOL forwardSeekButtonHidden = NO;
    BOOL skipToLiveButtonHidden = NO;
    BOOL viewModeButtonHidden = NO;
    BOOL pictureInPictureButtonHidden = NO;
    BOOL timeSliderHidden = NO;
    BOOL durationLabelHidden = NO;
    BOOL tracksButtonHidden = NO;
    
    CGFloat controlsHeight = CGRectGetHeight(self.frame);
    if (controlsHeight < 165.f) {
        skipToLiveButtonHidden = YES;
        timeSliderHidden = YES;
        durationLabelHidden = YES;
    }
    if (controlsHeight < 120.f) {
        backwardSeekButtonHidden = YES;
        forwardSeekButtonHidden = YES;
        viewModeButtonHidden = YES;
        pictureInPictureButtonHidden = YES;
        tracksButtonHidden = YES;
    }
    
    CGFloat controlsWidth = CGRectGetWidth(self.frame);
    if (controlsWidth < 290.f) {
        skipToLiveButtonHidden = YES;
        timeSliderHidden = YES;
        durationLabelHidden = YES;
    }
    if (controlsWidth < 215.f) {
        backwardSeekButtonHidden = YES;
        forwardSeekButtonHidden = YES;
        viewModeButtonHidden = YES;
        pictureInPictureButtonHidden = YES;
        tracksButtonHidden = YES;
    }
    
    self.backwardSeekButton.hidden = backwardSeekButtonHidden;
    self.forwardSeekButton.hidden = forwardSeekButtonHidden;
    self.skipToLiveButton.hidden = skipToLiveButtonHidden;
    self.viewModeButton.alwaysHidden = viewModeButtonHidden;
    self.pictureInPictureButton.alwaysHidden = pictureInPictureButtonHidden;
    self.timeSlider.hidden = timeSliderHidden;
    self.durationLabel.hidden = durationLabelHidden;
    self.tracksButton.alwaysHidden = tracksButtonHidden;
}

- (void)updateFonts
{
    self.timeSlider.timeLeftValueLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)updateLayoutForController:(SRGLetterboxController *)controller
{
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    // General playback controls
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        self.forwardSeekButton.alpha = 0.f;
        self.backwardSeekButton.alpha = 0.f;
        self.skipToLiveButton.alpha = [controller canSkipToLive] ? 1.f : 0.f;
        
        self.timeSlider.alpha = 0.f;
        self.timeSlider.timeLeftValueLabel.hidden = YES;
    }
    else {
        self.forwardSeekButton.alpha = [controller canSkipForward] ? 1.f : 0.f;
        self.backwardSeekButton.alpha = [controller canSkipBackward] ? 1.f : 0.f;
        self.skipToLiveButton.alpha = [controller canSkipToLive] ? 1.f : 0.f;
        
        switch (mediaPlayerController.streamType) {
            case SRGMediaPlayerStreamTypeOnDemand: {
                self.timeSlider.alpha = 1.f;
                self.timeSlider.timeLeftValueLabel.hidden = NO;
                break;
            }
                
            case SRGMediaPlayerStreamTypeLive: {
                self.timeSlider.alpha = 0.f;
                self.timeSlider.timeLeftValueLabel.hidden = NO;
                break;
            }
                
            case SRGMediaPlayerStreamTypeDVR: {
                self.timeSlider.alpha = 1.f;
                // Hide timeLeftValueLabel to give the width space to the timeSlider
                self.timeSlider.timeLeftValueLabel.hidden = YES;
                break;
            }
                
            default: {
                self.timeSlider.alpha = 0.f;
                self.timeSlider.timeLeftValueLabel.hidden = YES;
                break;
            }
        }
    }
    
    // Play button / loading indicator visibility
    // TODO: Factor out
    BOOL isPlayerLoading = mediaPlayerController && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePlaying
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePaused
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle;
    
    BOOL visible = isPlayerLoading || controller.dataAvailability == SRGLetterboxDataAvailabilityLoading;
    if (visible) {
        self.playbackButton.alpha = 0.f;
    }
    else {
        self.playbackButton.alpha = 1.f;
    }
}

- (void)updateTimeLabelsForController:(SRGLetterboxController *)controller
{
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

- (IBAction)toggleFullScreen:(id)sender
{
    [self.delegate controlsViewDidToggleFullScreen:self];
}

- (IBAction)skipToLive:(id)sender
{
    [self.controller skipToLiveWithCompletionHandler:nil];
}

@end
