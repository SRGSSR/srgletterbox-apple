//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(tvos)
@interface PlayerPageViewController : UIViewController <SRGAnalyticsViewTracking>

- (instancetype)initWithURN:(NSString *)URN;

@property (nonatomic, readonly, copy) NSString *URN;

@end

@interface PlayerPageViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
