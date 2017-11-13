//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Paths of standard supplied vector images.
OBJC_EXTERN NSString *SRGLetterboxMediaPlaceholderFilePath(void);                  // Media placeholder (16:9 usual ratio).
OBJC_EXTERN NSString *SRGLetterboxMediaArtworkPlaceholderFilePath(void);           // Media artwork placeholder (1:1 ratio).

/**
 *  Return the image URL for an object and width, `nil` if the image URL is not found or invalid.
 *
 *  @discussion If some images have been overridden by local versions (see SRGDataProvider NSURL+SRGDataProvider.h file),
 *              the returned URL might be a file URL.
 */
OBJC_EXTERN NSURL * _Nullable SRGLetterboxImageURL(id<SRGImage> _Nullable object, CGFloat width, SRGImageType type);

/**
 *  Return the (square) artwork image URL for an object, with a given dimension.
 *
 *  @discussion If some images have been overridden by local versions (see SRGDataProvider NSURL+SRGDataProvider.h file),
 *              the returned URL might be a file URL.
 */
OBJC_EXTERN NSURL * _Nullable SRGLetterboxArtworkImageURL(id<SRGImage> _Nullable object, CGFloat dimension);

/**
 *  Available image scales.
 */
typedef NS_ENUM(NSInteger, SRGImageScale) {
    SRGImageScaleSmall,
    SRGImageScaleMedium,
    SRGImageScaleLarge
};

/**
 *  Available image sets.
 */
typedef NS_ENUM(NSInteger, SRGImageSet) {
    SRGImageSetNormal,
    SRGImageSetLarge
};

/**
 *  Return the recommended size matching a given image scale.
 */
OBJC_EXTERN CGSize SRGSizeForImageScale(SRGImageScale imageScale);

/**
 *  Standard images from Letterbox bundle.
 */
@interface UIImage (SRGLetterboxImages)

/**
 *  Playback buttons.
 */
+ (UIImage *)srg_letterboxPlayImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxPauseImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxStopImageInSet:(SRGImageSet)imageSet;

+ (UIImage *)srg_letterboxSeekForwardImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxSeekBackwardImageInSet:(SRGImageSet)imageSet;
+ (UIImage *)srg_letterboxSkipToLiveImageInSet:(SRGImageSet)imageSet;

/**
 *  Return the standard image to be used for a given letterbox error.
 */
+ (nullable UIImage *)srg_letterboxImageForError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
