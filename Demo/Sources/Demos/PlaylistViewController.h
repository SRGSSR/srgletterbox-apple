//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGLetterbox;
@import SRGDataProvider;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(tvos)
@interface PlaylistViewController : UIViewController <SRGAnalyticsViewTracking, SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate>

- (instancetype)initWithMedias:(nullable NSArray<SRGMedia *> *)medias sourceUid:(nullable NSString *)sourceUid;

@end

@interface PlaylistViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
