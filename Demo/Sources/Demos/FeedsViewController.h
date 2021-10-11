//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Demo feeds.
 */
typedef API_UNAVAILABLE(tvos) NS_ENUM(NSInteger, Feed) {
    /**
     *  RTS trending videos.
     */
    FeedRTSTrendingMedias,
    /**
     *  RSI trending videos.
     */
    FeedRSITrendingMedias,
    /**
     *  SRF trending videos.
     */
    FeedSRFTrendingMedias
};

API_UNAVAILABLE(tvos)
@interface FeedsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) Feed feed;

@end

NS_ASSUME_NONNULL_END
