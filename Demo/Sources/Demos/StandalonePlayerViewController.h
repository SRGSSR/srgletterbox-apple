//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProvider;
@import SRGLetterbox;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(tvos)
@interface StandalonePlayerViewController : UIViewController <SRGAnalyticsViewTracking, SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate>

- (instancetype)initWithURN:(nullable NSString *)URN;

@end

@interface StandalonePlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
