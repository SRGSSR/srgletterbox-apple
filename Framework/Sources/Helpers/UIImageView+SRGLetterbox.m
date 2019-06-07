//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImageView+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@implementation UIImageView (SRGLetterbox)

#pragma mark Class methods

+ (UIImageView *)srg_loadingImageView48WithTintColor:(UIColor *)tintColor
{
    return [self srg_animatedImageViewNamed:@"loading-48" withTintColor:tintColor duration:1.];
}

// Expect a sequence of images named "name-N", where N must begin at 0. Stops when no image is found for some N
+ (UIImageView *)srg_animatedImageViewNamed:(NSString *)name withTintColor:(UIColor *)tintColor duration:(NSTimeInterval)duration
{
    NSArray<UIImage *> *images = [self srg_animatedImageNamed:name withTintColor:tintColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:images.firstObject];
    imageView.animationImages = [images copy];
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
                                     inBundle:NSBundle.srg_letterboxBundle
                compatibleWithTraitCollection:nil] srg_imageTintedWithColor:tintColor];
        if (! image) {
            break;
        }
        [images addObject:image];
        
        ++count;
    }
    
    NSAssert(images.count != 0, @"Invalid asset %@", name);
    return [images copy];
}

#pragma mark Standard image loading

- (void)srg_requestImageForObject:(id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type
            unavailabilityHandler:(void (^)(void))unavailabilityHandler
{
    CGSize size = SRGSizeForImageScale(scale);
    UIImage *placeholderImage = [UIImage srg_vectorImageAtPath:SRGLetterboxMediaPlaceholderFilePath() withSize:size];
    
    NSURL *URL = SRGLetterboxImageURL(object, size.width, type);
    if (! URL) {
        if (unavailabilityHandler) {
            unavailabilityHandler();
        }
        else {
            
        }
        return;
    }
    
    
}

- (void)srg_requestImageForObject:(id<SRGImage>)object withScale:(SRGImageScale)scale type:(SRGImageType)type
{
    [self srg_requestImageForObject:object withScale:scale type:type unavailabilityHandler:nil];
}

- (void)srg_resetImage
{
    
}

@end
