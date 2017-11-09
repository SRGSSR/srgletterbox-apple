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
typedef NS_ENUM(NSInteger, AutoplayList) {
    /**
     *  Unknown list.
     */
    AutoplayListUnknown = 0,
    /**
     *  SRF trending videos.
     */
    AutoplayListSRFTrendingMedias,
    /**
     *  RTS trending videos.
     */
    AutoplayListRTSTrendingMedias,
    /**
     *  RSI trending videos.
     */
    AutoplayListRSITrendingMedias
};

@interface AutoplayViewController : UITableViewController

@property (nonatomic) AutoplayList autoplayList;

@end

NS_ASSUME_NONNULL_END
