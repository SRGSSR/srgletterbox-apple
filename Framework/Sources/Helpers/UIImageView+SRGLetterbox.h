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
 *
 *  @return `YES` iff a valid image URL could be found.
 */
// FIXME: Image validity should not have to be checked, but some services are returning bad URLs. When this has been
//        fixed, return void
- (BOOL)srg_requestImageForObject:(nullable id<SRGImageMetadata>)object
                        withScale:(SRGImageScale)imageScale;

@end

NS_ASSUME_NONNULL_END
