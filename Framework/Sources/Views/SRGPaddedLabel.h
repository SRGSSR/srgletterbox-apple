//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Padded label with custom margins
 *
 *  @discussion: Set `backgroundColor`, `textColor` and `layer.cornerRadius` to customize the pad.
 */
@interface SRGPaddedLabel : UILabel

@property (nonatomic) CGFloat horizontalMargin; // Apply at left and right
@property (nonatomic) CGFloat verticalMargin;   // Apply at top and bottom

@end
