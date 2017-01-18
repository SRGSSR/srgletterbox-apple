//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SRGLetterbox)

/**
 *  Return the receiver, tinted with the specified color (if color is `nil`, the image is returned as is)
 */
- (UIImage *)srg_imageTintedWithColor:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
