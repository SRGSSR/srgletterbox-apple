//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

const NSInteger SRGLetterboxBackwardSeekInterval = 30.;
const NSInteger SRGLetterboxForwardSeekInterval = 30.;

NSString * const SRGLetterboxMetadataDidChangeNotification = @"SRGLetterboxMetadataDidChangeNotification";

NSString * const SRGLetterboxServiceURNKey = @"SRGLetterboxServiceURNKey";
NSString * const SRGLetterboxMediaKey = @"SRGLetterboxMediaKey";
NSString * const SRGLetterboxMediaCompositionKey = @"SRGLetterboxMediaCompositionKey";
NSString * const SRGLetterboxPreferredQualityKey = @"SRGLetterboxPreferredQualityKey";

NSString * const SRGLetterboxPreviousURNKey = @"SRGLetterboxPreviousURNKey";
NSString * const SRGLetterboxPreviousMediaKey = @"SRGLetterboxPreviousMediaKey";
NSString * const SRGLetterboxPreviousMediaCompositionKey = @"SRGLetterboxPreviousMediaCompositionKey";
NSString * const SRGLetterboxPreferredQualityKey = @"SRGLetterboxPreferredQualityKey";

NSString * const SRGLetterboxPlaybackDidFailNotification = @"SRGLetterboxPlaybackDidFailNotification";


@interface SRGLetterboxController ()

// For successive seeks, update the target time (previous seeks are cancelled). This makes it possible to seek faster
// to a desired location
@property (nonatomic) CMTime seekTargetTime;

@end

@implementation SRGLetterboxController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.seekTargetTime = kCMTimeInvalid;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:self];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Standard seeks

- (BOOL)canSeekBackward
{
    return [self canSeekBackwardFromTime:[self seekStartTime]];
}

- (BOOL)canSeekForward
{
    return [self canSeekForwardFromTime:[self seekStartTime]];
}

- (void)seekBackwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self seekBackwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

- (void)seekForwardWithCompletionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self seekForwardFromTime:[self seekStartTime] withCompletionHandler:completionHandler];
}

#pragma mark Helpers

- (CMTime)seekStartTime
{
    return CMTIME_IS_VALID(self.seekTargetTime) ? self.seekTargetTime : self.player.currentTime;
}

- (BOOL)canSeekBackwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time)) {
        return NO;
    }
    
    return (self.streamType == SRGMediaPlayerStreamTypeOnDemand || self.streamType == SRGMediaPlayerStreamTypeDVR);
}

- (BOOL)canSeekForwardFromTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time)) {
        return NO;
    }
    
    return (self.streamType == SRGMediaPlayerStreamTypeOnDemand && CMTimeGetSeconds(time) + SRGLetterboxForwardSeekInterval < CMTimeGetSeconds(self.player.currentItem.duration))
        || (self.streamType == SRGMediaPlayerStreamTypeDVR && !self.live);
}

- (void)seekBackwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (![self canSeekBackwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    self.seekTargetTime = CMTimeSubtract(time, CMTimeMakeWithSeconds(SRGLetterboxBackwardSeekInterval, NSEC_PER_SEC));
    [self seekEfficientlyToTime:self.seekTargetTime withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

- (void)seekForwardFromTime:(CMTime)time withCompletionHandler:(void (^)(BOOL finished))completionHandler
{
    if (![self canSeekForwardFromTime:time]) {
        completionHandler ? completionHandler(NO) : nil;
        return;
    }
    
    self.seekTargetTime = CMTimeAdd(time, CMTimeMakeWithSeconds(SRGLetterboxForwardSeekInterval, NSEC_PER_SEC));
    [self seekEfficientlyToTime:self.seekTargetTime withCompletionHandler:^(BOOL finished) {
        if (finished) {
            [self play];
        }
        completionHandler ? completionHandler(finished) : nil;
    }];
}

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    if (playbackState != SRGMediaPlayerPlaybackStateSeeking) {
        self.seekTargetTime = kCMTimeInvalid;
    }
}

@end
