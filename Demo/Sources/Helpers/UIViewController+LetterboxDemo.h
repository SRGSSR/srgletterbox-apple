//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>

#import "Playlist.h"

NS_ASSUME_NONNULL_BEGIN

/**
*  Protocol to support tvOS continuous playback at the end of a plack media.
*/
@protocol SRGLetterboxDemoTVOSContinuePlayback <NSObject>

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) Playlist *playlist;

@end

@interface UIViewController (LetterboxDemo)

- (void)openPlayerWithURN:(NSString *)URN serviceURL:(nullable NSURL *)serviceURL updateInterval:(nullable NSNumber *)updateInterval;

@end

NS_ASSUME_NONNULL_END
