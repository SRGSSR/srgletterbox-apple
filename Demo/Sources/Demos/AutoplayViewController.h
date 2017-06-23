//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Auto Play list
 */
typedef NS_ENUM(NSInteger, AutoPlayList) {
    /**
     *  Unknown list.
     */
    AutoPlayListUnknown = 0,
    /**
     *  Most popular RTS video.
     */
    AutoPlayListMostPopularRTSVideo,
    /**
     *  SRF video scheduled livestreams
     */
    AutoPlayListSRFVideoScheduledLivestreams,
    /**
     *  Most populare RTS video.
     */
    AutoPlayListRTSVideoScheduledLivestreams,
    /**
     *  Most populare RTS video.
     */
    AutoPlayListRSIVideoScheduledLivestreams
};

@interface AutoplayViewController : UITableViewController

@property (nonatomic) AutoPlayList autoPlayList;

@end

NS_ASSUME_NONNULL_END
