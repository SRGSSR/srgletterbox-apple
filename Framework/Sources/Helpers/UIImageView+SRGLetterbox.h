//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+SRGLetterbox.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (SRGLetterbox)

/**
 *  Standard loading indicators
 */
+ (UIImageView *)srg_loadingImageView35WithTintColor:(nullable UIColor *)tintColor;

- (void)srg_startAnimatingLoading35WithTintColor:(nullable UIColor *)tintColor;
- (void)srg_stopAnimating;

- (void)srg_requestImageForObject:(id<SRGImageMetadata>)object
                        withScale:(SRGImageScale)imageScale
             placeholderImageName:(nullable NSString *)placeholderImageName;
- (void)srg_cancelCurrentImageRequest;

@end

NS_ASSUME_NONNULL_END
