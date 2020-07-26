//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"
#import "UIImage+SRGLetterbox.h"

/**
 *  Playback button.
 */
API_UNAVAILABLE(tvos)
@interface SRGLetterboxPlaybackButton : UIButton

/**
 *  The controller which the button is associated with.
 */
@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

/**
 *  The image set to use. Default is `SRGImageSetNormal`.
 */
@property (nonatomic) SRGImageSet imageSet;

@end
