//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  MediaList types
 */
typedef NS_ENUM(NSInteger, MediaListType) {
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
     *  MMF Topic list
     */
    MediaListMMFTopicList
};

@interface MediaListViewController : UITableViewController

- (instancetype)initWithMediaListType:(MediaListType)mediaListType uid:(nullable NSString *)uid;

@property (nonatomic, readonly) MediaListType mediaListType;

@property (nonatomic, readonly, nullable) NSString *uid;

@end

NS_ASSUME_NONNULL_END
