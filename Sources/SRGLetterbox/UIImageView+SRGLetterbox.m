//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImageView+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGProgram+SRGLetterbox.h"
#import "UIColor+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

@import SRGAppearance;
@import YYWebImage;

@implementation UIImageView (SRGLetterbox)

#pragma mark Class methods

+ (UIImageView *)srg_loadingImageViewWithTintColor:(UIColor *)tintColor
{
    return [self srg_animatedImageViewNamed:@"loading" withTintColor:tintColor duration:1.];
}

// Expect a sequence of images named "name-N", where N must begin at 0. Stops when no image is found for some N
+ (UIImageView *)srg_animatedImageViewNamed:(NSString *)name withTintColor:(UIColor *)tintColor duration:(NSTimeInterval)duration
{
    NSArray<UIImage *> *images = [self srg_animatedImageNamed:name withTintColor:tintColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:images.firstObject];
    imageView.animationImages = images.copy;
    imageView.animationDuration = duration;
    return imageView;
}

+ (NSArray<UIImage *> *)srg_animatedImageNamed:(NSString *)name withTintColor:(UIColor *)tintColor
{
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    
    NSInteger count = 0;
    while (1) {
        NSString *imageName = [NSString stringWithFormat:@"%@-%@", name, @(count)];
        UIImage *image = [[UIImage imageNamed:imageName
                                     inBundle:SWIFTPM_MODULE_BUNDLE
                compatibleWithTraitCollection:nil] srg_imageTintedWithColor:tintColor];
        if (! image) {
            break;
        }
        [images addObject:image];
        
        ++count;
    }
    
    NSAssert(images.count != 0, @"Invalid asset %@", name);
    return images.copy;
}

#pragma mark Standard image loading

- (void)srg_requestImageForObject:(id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type
            unavailabilityHandler:(void (^)(void))unavailabilityHandler
{
    CGFloat width = SRGWidthForImageScale(scale);
    UIImage *placeholderImage = [UIImage srg_vectorImageAtPath:SRGLetterboxFilePathForImagePlaceholder() withWidth:width];
    
    NSURL *URL = SRGLetterboxImageURL(object, width, type);
    if (! URL) {
        if (unavailabilityHandler) {
            unavailabilityHandler();
        }
        else {
            [self yy_setImageWithURL:nil placeholder:placeholderImage];
            self.backgroundColor = UIColor.srg_placeholderBackgroundGrayColor;
        }
        return;
    }
    
    YYWebImageCompletionBlock completion = ^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
        self.backgroundColor = (! error && image) ? UIColor.clearColor : UIColor.srg_placeholderBackgroundGrayColor;
    };
    
    if (! [URL isEqual:self.yy_imageURL]) {
        // If an image is already displayed, use it as placeholder. This make the transition smooth between both images.
        // Using the placeholder would add an unnecessary intermediate state leading to flickering
        if (self.image) {
            [self yy_setImageWithURL:URL placeholder:self.image options:YYWebImageOptionSetImageWithFadeAnimation completion:completion];
        }
        // If no image is already displayed, check if the image we want to display is already available from the cache.
        // If this is the case, use it as placeholder, avoiding an intermediate step which would lead to flickering
        else {
            YYWebImageManager *webImageManager = [YYWebImageManager sharedManager];
            NSString *key = [webImageManager cacheKeyForURL:URL];
            UIImage *image = [webImageManager.cache getImageForKey:key];
            if (image) {
                // Use the YYWebImage setter so that the URL is properly associated with the image view
                [self yy_setImageWithURL:URL placeholder:image options:YYWebImageOptionSetImageWithFadeAnimation completion:completion];
            }
            else {
                self.backgroundColor = UIColor.srg_placeholderBackgroundGrayColor;
                [self yy_setImageWithURL:URL placeholder:placeholderImage options:YYWebImageOptionSetImageWithFadeAnimation completion:completion];
            }
        }
    }
}

- (void)srg_requestImageForObject:(id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type
{
    [self srg_requestImageForObject:object withScale:scale type:type unavailabilityHandler:nil];
}

- (void)srg_resetImage
{
    [self yy_setImageWithURL:nil options:0];
    self.backgroundColor = UIColor.clearColor;
}

@end
