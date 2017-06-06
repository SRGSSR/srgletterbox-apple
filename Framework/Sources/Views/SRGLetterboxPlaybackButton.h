//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "UIImage+SRGLetterbox.h"

/**
 *  Playback button.
 */
@interface SRGLetterboxPlaybackButton : SRGPlaybackButton

/**
*  Switch from Pause image to Stop image for the play / pause image.
*/
@property (nonatomic) BOOL usesStopImage;

/**
 *  Switch the image set.
 */
@property (nonatomic) SRGImageSet imageSet;

@end
