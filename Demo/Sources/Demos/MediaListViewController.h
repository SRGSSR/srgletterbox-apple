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
     *  MMF topic
     */
    MediaListMMFTopic
};

@interface MediaListViewController : UITableViewController

- (instancetype)initWithMediaListType:(MediaListType)mediaListType URN:(nullable NSString *)URN;

@property (nonatomic, readonly) MediaListType mediaListType;

@property (nonatomic, readonly, nullable) NSString *URN;

@end

NS_ASSUME_NONNULL_END
