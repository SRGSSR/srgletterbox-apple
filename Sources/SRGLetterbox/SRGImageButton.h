//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A simple control resembling an image button, calling the action defined for the `UIControlEventPrimaryActionTriggered´
 *  event when pressed.
 */
API_AVAILABLE(tvos(9.0)) API_UNAVAILABLE(ios)
@interface SRGImageButton : UIControl

/**
 *  The image view displaying the button image.
 */
@property (nonatomic, readonly) UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
