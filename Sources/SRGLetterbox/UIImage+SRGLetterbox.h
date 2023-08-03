//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Available image sets.
 */
typedef NS_ENUM(NSInteger, SRGImageSet) {
    SRGImageSetNormal = 0,
    SRGImageSetLarge
};

/**
 *  Return the file path for the default media placeholder.
 */
OBJC_EXPORT NSString *SRGLetterboxFilePathForImagePlaceholder(void);

/**
 *  Return the image URL for an image and size, retrieved on behalf of the provided controller.
 */
OBJC_EXPORT NSURL * _Nullable SRGLetterboxImageURL(SRGImage * _Nullable image, SRGImageSize size, SRGLetterboxController * _Nullable controller);

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


+ (UIImage *)srg_letterboxStartOverImageInSet:(SRGImageSet)imageSet;
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
