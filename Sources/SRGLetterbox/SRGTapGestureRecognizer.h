//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Default delay between consecutive taps.
 */
OBJC_EXPORT const NSTimeInterval SRGTapGestureRecognizerDelay;

/**
 *  Custom tap gesture recognizer with customizable delay between taps. Mostly useful when the default
 *  `UITapGestureRecognizer` does not fail fast enough.
 */
@interface SRGTapGestureRecognizer : UITapGestureRecognizer

/**
 *  Delay between consecutive taps (only meaningful if `numberOfTapsRequired` > 1).
 */
@property (nonatomic) NSTimeInterval tapDelay;

@end

NS_ASSUME_NONNULL_END
