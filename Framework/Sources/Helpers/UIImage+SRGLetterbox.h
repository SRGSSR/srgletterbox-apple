//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SRGImageScale) {
    SRGImageScaleSmall,
    SRGImageScaleMedium,
    SRGImageScaleLarge
};

OBJC_EXTERN CGSize SRGSizeForImageScale(SRGImageScale imageScale);

@interface UIImage (SRGLetterbox)

/**
 *  Resize a given vector image to a given size
 */
+ (UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(nullable NSBundle *)bundle withSize:(CGSize)size;

/**
 *  Resize a given vector image to a given predefined scale
 */
+ (UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(nullable NSBundle *)bundle  withScale:(SRGImageScale)imageScale;

/**
 *  Return the receiver, tinted with the specified color (if color is `nil`, the image is returned as is)
 */
- (UIImage *)srg_imageTintedWithColor:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
