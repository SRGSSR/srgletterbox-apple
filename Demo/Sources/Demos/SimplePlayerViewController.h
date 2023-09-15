//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(tvos)
@interface SimplePlayerViewController : UIViewController <SRGAnalyticsViewTracking>

- (instancetype)initWithURN:(nullable NSString *)URN;

@property (nonatomic, readonly, copy, nullable) NSString *URN;

@end

@interface SimplePlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
