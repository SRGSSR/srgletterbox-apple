//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImageView+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"
#import "NSBundle+SRGLetterbox.h"

#import <YYWebImage/YYWebImage.h>

@implementation UIImageView (SRGLetterbox)

#pragma mark Class methods

+ (UIImageView *)srg_loadingImageView35WithTintColor:(UIColor *)tintColor
{
    return [self srg_animatedImageViewNamed:@"loading-35" withTintColor:tintColor duration:1.];
}

// Expect a sequence of images named "name-N", where N must begin at 0. Stops when no image is found for some N
+ (UIImageView *)srg_animatedImageViewNamed:(NSString *)name withTintColor:(UIColor *)tintColor duration:(NSTimeInterval)duration
{
    NSArray<UIImage *> *images = [self animatedImageNamed:name withTintColor:tintColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:images.firstObject];
    imageView.animationImages = [images copy];
    imageView.animationDuration = duration;
    [imageView startAnimating];
    return imageView;
}

+ (NSArray<UIImage *> *)animatedImageNamed:(NSString *)name withTintColor:(UIColor *)tintColor {
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    
    NSInteger count = 0;
    while (1) {
        NSString *imageName = [NSString stringWithFormat:@"%@-%@", name, @(count)];
        UIImage *image = [[UIImage imageNamed:imageName
                                     inBundle:[NSBundle srg_letterboxBundle]
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

#pragma mark Loading animation

- (void)srg_startAnimatingLoading35WithTintColor:(nullable UIColor *)tintColor
{
    [self srg_startAnimatingWithImagesNamed:@"loading-35" withTintColor:tintColor];
}

- (void)srg_startAnimatingWithImagesNamed:(NSString *)name withTintColor:(nullable UIColor *)tintColor
{
    self.animationImages = [UIImageView animatedImageNamed:name withTintColor:tintColor];
    self.image = self.animationImages.firstObject;
    self.animationDuration = 1.;
    [self startAnimating];
}

- (void)srg_stopAnimating
{
    [self stopAnimating];
    self.animationImages = nil;
}

@end
