//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface Playlist : NSObject <SRGLetterboxControllerPlaylistDataSource>

- (instancetype)initWithMedias:(nullable NSArray<SRGMedia *> *)medias;

@property (nonatomic) NSTimeInterval continuousPlaybackTransitionDuration;
@property (nonatomic) CMTime startTime;

@property (nonatomic, readonly, nullable) NSArray<SRGMedia *> *medias;

@end

NS_ASSUME_NONNULL_END
