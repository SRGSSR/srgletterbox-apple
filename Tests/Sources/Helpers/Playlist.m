//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Playlist.h"

@interface Playlist ()

@property (nonatomic) NSOrderedSet<SRGMedia *> *mediasSet;

@end

@implementation Playlist

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<SRGMedia *> *)medias
{
    if (self = [super init]) {
        self.mediasSet = medias ? [NSOrderedSet orderedSetWithArray:medias] : [NSOrderedSet orderedSet];
    }
    return self;
}

#pragma mark Getters and setters

- (NSArray<SRGMedia *> *)medias
{
    return self.mediasSet.array;
}

#pragma mark Helpers

- (NSUInteger)currentIndexForMediaPlayedByController:(SRGLetterboxController *)controller
{
    SRGMediaURN *URN = controller.URN;
    if (URN) {
        return [self.mediasSet indexOfObjectPassingTest:^BOOL(SRGMedia * _Nonnull media, NSUInteger idx, BOOL * _Nonnull stop) {
            return [media.URN isEqual:URN];
        }];
    }
    else {
        return NSNotFound;
    }
}

#pragma SRGLetterboxControllerPlaylistDataSource protocol

- (SRGMedia *)previousMediaForController:(SRGLetterboxController *)controller
{
    NSUInteger index = [self currentIndexForMediaPlayedByController:controller];
    if (index != NSNotFound) {
        return (index > 0) ? self.mediasSet[index - 1] : nil;
    }
    else {
        return nil;
    }
}

- (SRGMedia *)nextMediaForController:(SRGLetterboxController *)controller
{
    NSUInteger index = [self currentIndexForMediaPlayedByController:controller];
    if (index != NSNotFound) {
        return (index < self.mediasSet.count - 1) ? self.mediasSet[index + 1] : nil;
    }
    else {
        return self.mediasSet.firstObject;
    }
}

@end
