//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Media lists
 */
typedef NS_ENUM(NSInteger, MediaList) {
    /**
     *  Not specified
     */
    MediaListUnknown = 0,
    /**
     *  Live center SRF
     */
    MediaListLiveCenterSRF,
    /**
     *  Live center RTS
     */
    MediaListLiveCenterRTS,
    /**
     *  Live center RSI
     */
    MediaListLiveCenterRSI,
    /**
     *  Latest by topic
     */
    MediaListLatestByTopic
};

@interface MediaListViewController : UITableViewController

- (instancetype)initWithMediaList:(MediaList)mediaList topic:(nullable SRGTopic *)topic serviceURL:(nullable NSURL *)serviceURL;

@property (nonatomic, readonly) MediaList mediaList;

@property (nonatomic, readonly, nullable) SRGTopic *topic;

@end

NS_ASSUME_NONNULL_END
