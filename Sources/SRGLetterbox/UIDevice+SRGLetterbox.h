//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (SRGLetterbox)

/**
 *  Return YES when the device is locked.
 */
@property (class, nonatomic, readonly) BOOL srg_letterbox_isLocked;

/**
 *  Return the kind of hardware the code is running on.
 */
@property (nonatomic, readonly, copy) NSString *srg_letterbox_hardware;

@end

NS_ASSUME_NONNULL_END
