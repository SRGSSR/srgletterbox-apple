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
     *  RTS trending videos.
     */
    AutoplayListRTSTrendingMedias,
    /**
     *  SRF live center videos.
     */
    AutoplayListSRFLiveCenterVideos,
    /**
     *  RTS live center videos.
     */
    AutoplayListRTSLiveCenterVideos,
    /**
     *  SRF live center videos.
     */
    AutoplayListRSILiveCenterVideos
};

@interface AutoplayViewController : UITableViewController

@property (nonatomic) AutoplayList autoplayList;

@end

NS_ASSUME_NONNULL_END
