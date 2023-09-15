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
@interface AdvancedPlayerViewController : UIViewController <SRGAnalyticsViewTracking, SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>

// If `media` is set, `URN` is ignored.
- (instancetype)initWithURN:(nullable NSString *)URN media:(nullable SRGMedia *)media serviceURL:(nullable NSURL *)serviceURL;

@property (nonatomic) NSTimeInterval updateInterval;

@end

@interface AdvancedPlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
