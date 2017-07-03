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
 *  @param type   The image type (use `SRGImageTypeDefault` for the default image).
 *
 *  @return `YES` iff a valid image URL could be found.
 */
// FIXME: Image validity should not have to be checked, but some services are returning bad URLs. When this has been
//        fixed, return void
- (BOOL)srg_requestImageForObject:(nullable id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type;

/**
 *  Reset the image to the placeholder and cancel any pending image request.
 */
- (void)srg_resetWithScale:(SRGImageScale)imageScale;

@end

NS_ASSUME_NONNULL_END
