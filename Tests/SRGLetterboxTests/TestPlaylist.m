//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TestPlaylist.h"

@interface TestPlaylist ()

@property (nonatomic) NSArray<SRGMedia *> *medias;
@property (nonatomic) NSInteger index;
@property (nonatomic, getter=isStandalone) BOOL standalone;

@end

@implementation TestPlaylist

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<SRGMedia *> *)medias standalone:(BOOL)standalone
{
    if (self = [super init]) {
        self.medias = medias;
        self.index = NSNotFound;
        self.continuousPlaybackTransitionDuration = SRGLetterboxContinuousPlaybackDisabled;
        self.startTime = kCMTimeZero;
        self.standalone = standalone;
    }
    return self;
}

#pragma SRGLetterboxControllerPlaylistDataSource protocol

- (SRGMedia *)previousMediaForController:(SRGLetterboxController *)controller
{
    if (self.medias.count == 0 || self.index == NSNotFound) {
        return nil;
    }
    else {
        return self.index > 0 ? self.medias[self.index - 1] : nil;
    }
}

- (SRGMedia *)nextMediaForController:(SRGLetterboxController *)controller
{
    if (self.medias.count == 0) {
        return nil;
    }
    else if (self.index == NSNotFound) {
        return self.medias.firstObject;
    }
    else {
        return self.index < self.medias.count - 1 ? self.medias[self.index + 1] : nil;
    }
}

- (void)controller:(SRGLetterboxController *)controller didChangeToMedia:(SRGMedia *)media
{
    self.index = [self.medias indexOfObject:media];
}

- (SRGPosition *)controller:(SRGLetterboxController *)controller startPositionForMedia:(SRGMedia *)media
{
    return [SRGPosition positionAtTime:self.startTime];
}

- (SRGLetterboxPlaybackSettings *)controller:(SRGLetterboxController *)controller preferredSettingsForMedia:(SRGMedia *)media
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = self.standalone;
    return settings;
}

#pragma SRGLetterboxControllerPlaybackTransitionDelegate protocol

- (NSTimeInterval)continuousPlaybackTransitionDurationForController:(SRGLetterboxController *)controller
{
    return self.continuousPlaybackTransitionDuration;
}

@end
