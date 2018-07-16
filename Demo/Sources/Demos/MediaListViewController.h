//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

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
     *  Livecenter SRF
     */
    MediaListLivecenterSRF,
    /**
     *  Livecenter RTS
     */
    MediaListLivecenterRTS,
    /**
     *  Livecenter RSI
     */
    MediaListLivecenterRSI,
    /**
     *  Latest by Topic
     */
    MediaListLatestByTopic
};

@interface MediaListViewController : UITableViewController

- (instancetype)initWithMediaList:(MediaList)MediaList topic:(nullable SRGTopic *)topic MMFOverride:(BOOL)MMFOverride;

@property (nonatomic, readonly) MediaList MediaList;

@property (nonatomic, readonly, nullable) SRGTopic *topic;

@property (nonatomic, readonly, getter=isMMFOverride) BOOL MMFOverride;

@end

NS_ASSUME_NONNULL_END
