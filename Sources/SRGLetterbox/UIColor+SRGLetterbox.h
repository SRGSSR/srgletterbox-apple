//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (SRGLetterbox)

/**
 *  The red color identifying live content.
 */
@property (class, nonatomic, readonly) UIColor *srg_liveRedColor;

/**
 *  Red color for displaying progress information.
 */
@property (class, nonatomic, readonly) UIColor *srg_progressRedColor;

/**
 *  Placeholder background color (same as the resource).
 */
@property (class, nonatomic, readonly) UIColor *srg_placeholderBackgroundGrayColor;

@end

NS_ASSUME_NONNULL_END
