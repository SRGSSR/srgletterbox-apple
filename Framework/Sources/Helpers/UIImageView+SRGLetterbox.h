//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+SRGLetterbox.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (SRGLetterbox)

/**
 *  Standard loading indicator. Call `-startAnimating` to animate.
 */
+ (UIImageView *)srg_loadingImageView48WithTintColor:(nullable UIColor *)tintColor;

/**
 *  Request an image of the specified object. Use `SRGImageTypeDefault` for the default image.
 *
 *  @param object                The object for which the image must be requested.
 *  @param scale                 The image scale.
 *  @param type                  The image type.
 *  @param unavailabilityHandler An optional handler called when the image is invalid (no object was provided or its
 *                               associated image is invalid). You can implement this block to respond to such cases,
 *                               e.g. to retrieve another image. If the block is set, no image will be set, otherwise
 *                               the default placeholder will automatically be set.
 */
- (void)srg_requestImageForObject:(nullable id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type
            unavailabilityHandler:(nullable void (^)(void))unavailabilityHandler;

/**
 *  Same as `-srg_requestImageForObject:withScale:type:unavailabilityHandler:`, with no unavailability handler (thus
 *  setting the default placeholder if no image is available).
 */
- (void)srg_requestImageForObject:(nullable id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type;

/**
 *  Reset the image and cancel any pending image request.
 */
- (void)srg_resetImage;

@end

NS_ASSUME_NONNULL_END
