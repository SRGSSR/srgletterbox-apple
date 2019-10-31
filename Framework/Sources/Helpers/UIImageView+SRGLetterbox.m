//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImageView+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGProgram+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>
#import <YYWebImage/YYWebImage.h>

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
                                     inBundle:NSBundle.srg_letterboxBundle
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
                      placeholder:(SRGLetterboxImagePlaceholder)placeholder
            unavailabilityHandler:(void (^)(void))unavailabilityHandler
{
    CGSize size = SRGSizeForImageScale(scale);
    UIImage *placeholderImage = [UIImage srg_vectorImageAtPath:SRGLetterboxFilePathForImagePlaceholder(placeholder) withSize:size];
    
    NSURL *URL = SRGLetterboxImageURL(object, size.width, type);
    if (! URL) {
        if (unavailabilityHandler) {
            unavailabilityHandler();
        }
        else {
            [self yy_setImageWithURL:nil placeholder:placeholderImage];
        }
        return;
    }
    
    if (! [URL isEqual:self.yy_imageURL]) {
        // If an image is already displayed, use it as placeholder. This make the transition smooth between both images.
        // Using the placeholder would add an unnecessary intermediate state leading to flickering
        if (self.image) {
            [self yy_setImageWithURL:URL placeholder:self.image options:YYWebImageOptionSetImageWithFadeAnimation completion:nil];
        }
        // If no image is already displayed, check if the image we want to display is already available from the cahce.
        // If this is the case, use it as placeholder, avoiding an intermediate step which would lead to flickering
        else {
            YYWebImageManager *webImageManager = [YYWebImageManager sharedManager];
            NSString *key = [webImageManager cacheKeyForURL:URL];
            UIImage *image = [webImageManager.cache getImageForKey:key];
            if (image) {
                // Use the YYWebImage setter so that the URL is properly associated with the image view
                [self yy_setImageWithURL:URL placeholder:image options:YYWebImageOptionSetImageWithFadeAnimation completion:nil];
            }
            else {
                [self yy_setImageWithURL:URL placeholder:placeholderImage options:YYWebImageOptionSetImageWithFadeAnimation completion:nil];
            }
        }
    }
}

- (void)srg_requestImageForObject:(id<SRGImage>)object
                        withScale:(SRGImageScale)scale
                             type:(SRGImageType)type
                      placeholder:(SRGLetterboxImagePlaceholder)placeholder
{
    [self srg_requestImageForObject:object withScale:scale type:type placeholder:placeholder unavailabilityHandler:nil];
}

- (void)srg_requestImageForController:(SRGLetterboxController *)controller
                            withScale:(SRGImageScale)scale
                                 type:(SRGImageType)type
                          placeholder:(SRGLetterboxImagePlaceholder)placeholder
                unavailabilityHandler:(void (^)(void))unavailabilityHandler
                               atDate:(NSDate *)date
{
    // For livestreams, rely on channel information when available
    SRGMedia *media = controller.subdivisionMedia ?: controller.media;
    if (media.contentType == SRGContentTypeLivestream && controller.channel) {
        SRGChannel *channel = controller.channel;
        
        // Display program artwork (if any) when the provided date falls within the current program, otherwise channel artwork.
        if (date && [channel.currentProgram srgletterbox_containsDate:date]) {
            [self srg_requestImageForObject:channel.currentProgram withScale:scale type:type placeholder:placeholder unavailabilityHandler:^{
                [self srg_requestImageForObject:channel withScale:scale type:type placeholder:placeholder unavailabilityHandler:unavailabilityHandler];
            }];
        }
        else {
            [self srg_requestImageForObject:channel withScale:scale type:type placeholder:placeholder unavailabilityHandler:unavailabilityHandler];
        }
    }
    else {
        [self srg_requestImageForObject:media withScale:scale type:type placeholder:placeholder unavailabilityHandler:unavailabilityHandler];
    }

}

- (void)srg_requestImageForController:(SRGLetterboxController *)controller
                            withScale:(SRGImageScale)scale
                                 type:(SRGImageType)type
                          placeholder:(SRGLetterboxImagePlaceholder)placeholder
                               atDate:(NSDate *)date
{
    [self srg_requestImageForController:controller withScale:scale type:type placeholder:placeholder unavailabilityHandler:nil atDate:date];
}

- (void)srg_resetImage
{
    [self yy_setImageWithURL:nil options:0];
}

@end
