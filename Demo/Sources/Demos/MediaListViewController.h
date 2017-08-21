//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import "DemosViewController.h"

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
    MediaListLivecenterRSI
};

@interface MediaListViewController : UITableViewController

- (instancetype)initWithMediaListType:(MediaListType)mediaListType;

@property (nonatomic, readonly) MediaListType mediaListType;

@end

NS_ASSUME_NONNULL_END
