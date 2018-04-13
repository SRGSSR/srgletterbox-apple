//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AutoplayTableViewCell.h"

#import "SettingsViewController.h"

#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>

@interface AutoplayTableViewCell ()

@property (nonatomic) SRGLetterboxController *letterboxController;
@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

@implementation AutoplayTableViewCell

#pragma mark Getters and setters

- (void)setMedia:(SRGMedia *)media
{
    _media = media;
    
    if (media) {
        [self.letterboxController playMedia:media standalone:NO];
    }
    else {
        [self.letterboxController reset];
    }
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.letterboxController = [[SRGLetterboxController alloc] init];
    self.letterboxController.serviceURL = ApplicationSettingServiceURL();
    self.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    self.letterboxController.globalHeaders = ApplicationSettingGlobalHeaders();
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

#pragma UI

- (void)updateProgressWithTime:(CMTime)time
{
    CMTimeRange timeRange = self.letterboxController.timeRange;
    if (CMTIMERANGE_IS_VALID(timeRange) && ! CMTIMERANGE_IS_EMPTY(timeRange)) {
        self.progressView.progress = CMTimeGetSeconds(CMTimeSubtract(time, timeRange.start)) / CMTimeGetSeconds(timeRange.duration);
        self.progressView.hidden = NO;
    }
    else {
        self.progressView.hidden = YES;
    }
}

@end
