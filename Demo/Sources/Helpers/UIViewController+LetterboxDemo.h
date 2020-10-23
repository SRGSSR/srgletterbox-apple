//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Playlist.h"

@import SRGDataProvider;
@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (LetterboxDemo)

- (void)openPlayerWithURN:(NSString *)URN;
- (void)openPlayerWithURN:(NSString *)URN serviceURL:(nullable NSURL *)serviceURL;
- (void)openPlayerWithMedia:(SRGMedia *)media serviceURL:(nullable NSURL *)serviceURL;

@end

NS_ASSUME_NONNULL_END
