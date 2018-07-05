//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Playlist.h"

@interface Playlist ()

@property (nonatomic) NSArray<SRGMedia *> *medias;
@property (nonatomic) NSInteger index;

@end

@implementation Playlist

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<SRGMedia *> *)medias
{
    if (self = [super init]) {
        self.medias = medias;
        self.index = NSNotFound;
        self.continuousPlaybackTransitionDuration = SRGLetterboxContinuousPlaybackTransitionDurationDisabled;
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

- (NSTimeInterval)continuousPlaybackTransitionDurationForController:(SRGLetterboxController *)controller
{
    return self.continuousPlaybackTransitionDuration;
}

- (void)controller:(SRGLetterboxController *)controller didTransitionToMedia:(SRGMedia *)media automatically:(BOOL)automatically
{
    self.index = [self.medias indexOfObject:media];
}

@end
