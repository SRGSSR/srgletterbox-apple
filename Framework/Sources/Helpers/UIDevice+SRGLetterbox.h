//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (SRGLetterbox)

/**
 *  Return YES when the device is locked.
 */
+ (BOOL)srg_letterbox_isLocked;

/**
 *  Return the kind of hardware the code is running on.
 */
@property (nonatomic, readonly, copy) NSString *hardware;

@end

NS_ASSUME_NONNULL_END
