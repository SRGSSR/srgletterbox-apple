//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface Playlist : NSObject <SRGLetterboxControllerPlaylistDataSource>

- (instancetype)initWithMedias:(nullable NSArray<SRGMedia *> *)medias sourceUid:(nullable NSString *)sourceUid;

@property (nonatomic) NSTimeInterval continuousPlaybackTransitionDuration;

@property (nonatomic, readonly, nullable) NSArray<SRGMedia *> *medias;
@property (nonatomic, readonly, copy, nullable) NSString *sourceUid;

@end

NS_ASSUME_NONNULL_END
