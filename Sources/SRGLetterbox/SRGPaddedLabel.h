//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Padded label with custom margins.
 */
@interface SRGPaddedLabel : UILabel

@property (nonatomic) IBInspectable CGFloat horizontalMargin; // Apply at left and right
@property (nonatomic) IBInspectable CGFloat verticalMargin;   // Apply at top and bottom

@end

NS_ASSUME_NONNULL_END
