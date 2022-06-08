//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"
#import "UIImage+SRGLetterbox.h"

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxPlaybackButton;

/**
 *  Playback button delegate.
 */
@protocol SRGLetterboxPlaybackButtonDelegate <NSObject>

/**
 *  Called when the button is toggled, with `paused` set to `YES` if the user paused playback.
 */
- (void)playbackButton:(SRGLetterboxPlaybackButton *)playbackButton didTogglePlayPause:(BOOL)paused;

@end

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

/**
 *  The playback button delegate.
 */
@property (nonatomic, weak) id<SRGLetterboxPlaybackButtonDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
