//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Paths of standard supplied vector images.
OBJC_EXTERN NSString *SRGLetterboxMediaPlaceholderFilePath(void);                  // Media placeholder

/**
 *  Return the image URL for an object and size, `nil` if the image URL is not found or invalid.
 *
 *  @discussion If some images have been overridden by local versions (see SRGDataProvider NSURL+SRGDataProvider.h file),
 *              the returned URL might be a file URL.
 */
OBJC_EXTERN NSURL * _Nullable SRGLetterboxImageURL(id<SRGImageMetadata> _Nullable object, CGSize size);

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
+ (UIImage *)srg_letterboxSeekToLiveImageInSet:(SRGImageSet)imageSet;

@end

NS_ASSUME_NONNULL_END
