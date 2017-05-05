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
+ (UIImageView *)srg_loadingImageView35WithTintColor:(nullable UIColor *)tintColor;

/**
 *  Request the main image for the specified object, for a given scale.
 *
 *  @param object The object to request the image for.
 *  @param scale  The scale to use.
 */
- (void)srg_requestImageForObject:(nullable id<SRGImageMetadata>)object
                        withScale:(SRGImageScale)imageScale;

/**
 *  Request the main image of the first object for which a valid image is available.
 *
 *  @param objects The objects to consider, in order.
 *  @param scale   The scale to use
 */
// FIXME: This is an ugly fix for services with bad images. Remove when image services have been sanitized.
- (void)srg_requestFirstValidImageForObjects:(NSArray<id<SRGImageMetadata>> *)objects
                                   withScale:(SRGImageScale)imageScale;

/**
 *  Cancel any running image request.
 */
- (void)srg_cancelCurrentImageRequest;

@end

NS_ASSUME_NONNULL_END
