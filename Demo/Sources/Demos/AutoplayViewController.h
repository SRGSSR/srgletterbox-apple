//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Autoplay lists.
 */
typedef API_UNAVAILABLE(tvos) NS_ENUM(NSInteger, AutoplayList) {
    /**
     *  RTS trending videos.
     */
    AutoplayListRTSTrendingMedias,
    /**
     *  RSI trending videos.
     */
    AutoplayListRSITrendingMedias,
    /**
     *  SRF trending videos.
     */
    AutoplayListSRFTrendingMedias
};

API_UNAVAILABLE(tvos)
@interface AutoplayViewController : UITableViewController

@property (nonatomic) AutoplayList autoplayList;

@end

NS_ASSUME_NONNULL_END
