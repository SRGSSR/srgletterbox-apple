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
 *  Standard loading indicators. Call `-startAnimating` to animate.
 */
+ (UIImageView *)srg_loadingImageView35WithTintColor:(nullable UIColor *)tintColor;

- (void)srg_startAnimatingLoading35WithTintColor:(nullable UIColor *)tintColor;
- (void)srg_stopAnimating;

/**
 *  Remark: If object is nil, the placeholder will also be used
 */
- (void)srg_requestImageForObject:(nullable id<SRGImageMetadata>)object
                        withScale:(SRGImageScale)imageScale
             placeholderImageName:(nullable NSString *)placeholderImageName;
- (void)srg_cancelCurrentImageRequest;

@end

NS_ASSUME_NONNULL_END
