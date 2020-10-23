//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Topic lists
 */
typedef NS_ENUM(NSInteger, TopicList) {
    /**
     *  Not specified
     */
    TopicListUnknown = 0,
    /**
     *  SRF Topics
     */
    TopicListSRF,
    /**
     *  RTS Topics
     */
    TopicListRTS,
    /**
     *  RSI Topics
     */
    TopicListRSI,
    /**
     *  RTR Topics
     */
    TopicListRTR,
    /**
     *  SWI Topics
     */
    TopicListSWI,
    /**
     *  MMF topics
     */
    TopicListMMF
};

@interface TopicListViewController : UITableViewController

- (instancetype)initWithTopicList:(TopicList)topicList;

@property (nonatomic, readonly) TopicList topicList;

@end

NS_ASSUME_NONNULL_END
