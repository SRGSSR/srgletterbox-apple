//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"
#import "UIImage+SRGLetterbox.h"

@import SRGDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (SRGLetterbox)

/**
 *  Standard loading indicator. Call `-startAnimating` to animate.
 */
+ (UIImageView *)srg_loadingImageViewWithTintColor:(nullable UIColor *)tintColor;

/**
 *  Request an image, caching it appropriately and calling a handler when no image is available.
 *
 *  @param image                 The image to request.
 *  @param size                  The image size.
 *  @param controller            The controller for which image retrieval is made.
 *  @param unavailabilityHandler An optional handler called when the image is invalid (no object was provided or its
 *                               associated image is invalid). You can implement this block to respond to such cases,
 *                               e.g. to retrieve another image. If the block is set, no image will be set, otherwise
 *                               the specified placeholder will automatically be set.
 *
 *  @discussion The background color is automatically adjusted.
 */
- (void)srg_requestImage:(nullable SRGImage *)image
                withSize:(SRGImageSize)size
              controller:(nullable SRGLetterboxController *)controller
   unavailabilityHandler:(nullable void (^)(void))unavailabilityHandler;

/**
 *  Same as `-srg_requestImage:withSize:unavailabilityHandler:`, with no unavailability handler (thus
 *  setting the default placeholder if no image is available).
 */
- (void)srg_requestImage:(nullable SRGImage *)image
                withSize:(SRGImageSize)size
              controller:(nullable SRGLetterboxController *)controller;

/**
 *  Reset the image and cancel any pending image request.
 */
- (void)srg_resetImage;

@end

NS_ASSUME_NONNULL_END
