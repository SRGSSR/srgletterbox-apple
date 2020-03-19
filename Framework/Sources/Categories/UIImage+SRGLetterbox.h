//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
 *  Types of placeholders available.
 */
typedef NS_ENUM(NSInteger, SRGLetterboxImagePlaceholder) {
    /**
     *  Media placeholder.
     */
    SRGLetterboxImagePlaceholderMedia,
    /**
     *  Artwork (square) placeholder.
     */
    SRGLetterboxImagePlaceholderArtwork,
    /**
     *  Large background placeholder, mostly for full-screen display on a TV.
     */
    SRGLetterboxImagePlaceholderBackground API_AVAILABLE(tvos(9.0)) API_UNAVAILABLE(ios)
};

/**
 *  Return the file path corresponding to the specified placeholder.
 */
OBJC_EXPORT NSString *SRGLetterboxFilePathForImagePlaceholder(SRGLetterboxImagePlaceholder imagePlaceholder);

/**
 *  Return the image URL for an object and width, `nil` if the image URL is not found or invalid.
 *
 *  @discussion If some images have been overridden by local versions (see SRGDataProvider NSURL+SRGDataProvider.h file),
 *              the returned URL might be a file URL.
 */
OBJC_EXPORT NSURL * _Nullable SRGLetterboxImageURL(id<SRGImage> _Nullable object, CGFloat width, SRGImageType type);

/**
 *  Return the (square) artwork image URL for an object, with a given dimension.
 *
 *  @discussion If some images have been overridden by local versions (see SRGDataProvider NSURL+SRGDataProvider.h file),
 *              the returned URL might be a file URL.
 */
OBJC_EXPORT NSURL * _Nullable SRGLetterboxArtworkImageURL(id<SRGImage> _Nullable object, CGFloat dimension);

/**
 *  Return the recommended size matching a given image scale and aspect ratio.
 */
OBJC_EXPORT CGSize SRGSizeForImageScale(SRGImageScale imageScale, CGFloat aspectRatio);

/**
 *  Standard images from Letterbox bundle.
 */
@interface UIImage (SRGLetterboxImages)

/**
 *  Return the specified image from the Letterbox bundle, `nil` if not found.
 */
+ (nullable UIImage *)srg_letterboxImageNamed:(NSString *)imageName;

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
+ (nullable UIImage *)srg_letterboxImageForError:(nullable NSError *)error;

/**
 *  Return the standard image to be used for a given blocking reason.
 */
+ (nullable UIImage *)srg_letterboxImageForBlockingReason:(SRGBlockingReason)blockingReason;

@end

NS_ASSUME_NONNULL_END
