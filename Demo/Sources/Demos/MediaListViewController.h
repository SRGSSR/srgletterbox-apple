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

@property (nonatomic) MediaListType mediaListType;

@property (nonatomic, weak) DemosViewController *demosViewController;

@end

NS_ASSUME_NONNULL_END
