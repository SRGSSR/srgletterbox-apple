//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (SRGLetterbox)

/**
 *  Standard loading indicators
 */
+ (UIImageView *)srg_loadingImageView35WithTintColor:(nullable UIColor *)tintColor;

- (void)srg_startAnimatingLoading35WithTintColor:(nullable UIColor *)tintColor;
- (void)srg_stopAnimating;

@end

NS_ASSUME_NONNULL_END
