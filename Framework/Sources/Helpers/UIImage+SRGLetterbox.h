//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Available image scales.
 */
typedef NS_ENUM(NSInteger, SRGImageScale) {
    SRGImageScaleSmall,
    SRGImageScaleMedium,
    SRGImageScaleLarge
};

/**
 *  Available image sets.
 */
typedef NS_ENUM(NSInteger, SRGImageSet) {
    SRGImageSetNormal,
    SRGImageSetLarge
};

/**
 *  Return the recommended size matching a given image scale.
 */
OBJC_EXTERN CGSize SRGSizeForImageScale(SRGImageScale imageScale);

@interface UIImage (SRGLetterbox)

/**
 *  Resize a given vector image to a given size.
 */
+ (nullable UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(nullable NSBundle *)bundle withSize:(CGSize)size;

/**
 *  Resize a given vector image for a predefined scale.
 */
+ (nullable UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(nullable NSBundle *)bundle withScale:(SRGImageScale)imageScale;

/**
 *  Return the receiver, tinted with the specified color (if color is `nil`, the image is returned as is).
 */
- (UIImage *)srg_imageTintedWithColor:(nullable UIColor *)color;

@end

/**
 *  Standard images from Letterbox bundle.
 */
@interface UIImage (SRGLetterboxImages)

/**
 *  Playback buttons.
 */
+ (UIImage *)srg_letterboxPlayImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxPauseImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxStopImageInSet:(SRGImageSet)imageSet;

+ (UIImage *)srg_letterboxSeekForwardImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxSeekBackwardImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxSeekToLiveImageInSet:(SRGImageSet)imageSet;

@end

NS_ASSUME_NONNULL_END
