//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "FeedTableViewCell.h"

#import "SettingsViewController.h"

#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>

@interface FeedTableViewCell ()

@property (nonatomic) SRGLetterboxController *letterboxController;
@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIImageView *soundIndicatorImageView;

@end

@implementation FeedTableViewCell

#pragma mark Getters and setters

- (void)setMedia:(SRGMedia *)media withPreferredSubtitleLocalization:(NSString *)preferredSubtitleLocalization
{
    if (media) {
        SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
        settings.standalone = ApplicationSettingStandalone();
        settings.quality = ApplicationSettingPreferredQuality();
        
        self.letterboxController.subtitleConfigurationBlock = ^AVMediaSelectionOption * _Nullable(NSArray<AVMediaSelectionOption *> * _Nonnull subtitleOptions, AVMediaSelectionOption * _Nullable audioOption, AVMediaSelectionOption * _Nullable defaultSubtitleOption) {
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
                return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:preferredSubtitleLocalization];
            }];
            return [subtitleOptions filteredArrayUsingPredicate:predicate].firstObject;
        };
        
        [self.letterboxController playMedia:media atPosition:nil withPreferredSettings:settings];
    }
    else {
        [self.letterboxController reset];
    }
}

- (BOOL)isMuted
{
    return self.letterboxController.muted;
}

- (void)setMuted:(BOOL)muted
{
    self.letterboxController.muted = muted;
    self.soundIndicatorImageView.image = muted ? [UIImage imageNamed:@"sound_off"] : [UIImage imageNamed:@"sound_on"];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.letterboxView.userInteractionEnabled = NO;
    self.progressView.userInteractionEnabled = NO;
    
    self.letterboxController = [[SRGLetterboxController alloc] init];
    self.letterboxController.serviceURL = ApplicationSettingServiceURL();
    self.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    self.letterboxController.globalParameters = ApplicationSettingGlobalParameters();
    self.letterboxController.backgroundVideoPlaybackEnabled = ApplicationSettingIsBackgroundVideoPlaybackEnabled();
    self.letterboxController.muted = YES;
    self.letterboxController.resumesAfterRouteBecomesUnavailable = YES;
    self.letterboxView.controller = self.letterboxController;
    
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:NO];
    [self.letterboxView setTimelineAlwaysHidden:YES animated:NO];
    
    [self updateProgressWithTime:kCMTimeZero];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.progressView.hidden = YES;
    
    self.letterboxController.muted = YES;
    self.soundIndicatorImageView.image = [UIImage imageNamed:@"sound_off"];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        @weakify(self)
        self.periodicTimeObserver = [self.letterboxController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            [self updateProgressWithTime:time];
        }];
    }
    else {
        [self.letterboxController removePeriodicTimeObserver:self.periodicTimeObserver];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // Fix issue stopping image view animations when the user taps the cell
    // See https://stackoverflow.com/questions/27904177/uiimageview-animation-stops-when-user-touches-screen/29330962
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    // Fix issue stopping image view animations when the user taps the cell
    // See https://stackoverflow.com/questions/27904177/uiimageview-animation-stops-when-user-touches-screen/29330962
}

#pragma UI

- (void)updateProgressWithTime:(CMTime)time
{
    CMTimeRange timeRange = self.letterboxController.timeRange;
    if (SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRange)) {
        self.progressView.progress = CMTimeGetSeconds(CMTimeSubtract(time, timeRange.start)) / CMTimeGetSeconds(timeRange.duration);
        self.progressView.hidden = NO;
    }
    else {
        self.progressView.hidden = YES;
    }
}

@end
