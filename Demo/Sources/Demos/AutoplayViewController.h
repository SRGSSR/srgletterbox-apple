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
typedef __TVOS_PROHIBITED NS_ENUM(NSInteger, AutoplayList) {
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

__TVOS_PROHIBITED
@interface AutoplayViewController : UITableViewController

@property (nonatomic) AutoplayList autoplayList;

@end

NS_ASSUME_NONNULL_END
