//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <AVKit/AVKit.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Delegate protocol for picture in picture implementation
 */
@protocol SRGLetterboxPictureInPictureDelegate <NSObject>

/**
 *  Called when picture in picture might need user interface restoration. Return YES if this is the case (most notably
 *  if the player view from which picture in picture was initiated is not visible anymore)
 */
- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture;

/**
 *  Called when a restoration process takes place
 *
 *  @parameter completionHandler A completion block which MUST be called at the VERY END of the restoration process
 *                               (e.g. after at the end of a modal presentation animation). Failing to do so leads to
 *                               undefined behavior. The completion block must be called with `restored` set to `YES`
 *                               iff the restoration was successful
 */
- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL restored))completionHandler;

@optional

/**
 *  Called when picture in picture has been started
 */
- (void)letterboxDidStartPictureInPicture;

/**
 *  Called when picture in picture stopped
 */
- (void)letterboxDidStopPictureInPicture;

@end

/**
 *  Service responsible for main media playback of a Letterbox controller throughout the application. The main controller
 *  is automatically integrated with the control center and enabled for external playback
 *
 *  @discussion Your target must support the 'Audio, Airplay, and Picture in Picture' capabilities, otherwise an exception
 *              will be thrown at runtime (this check is not performed for test targets)
 */
@interface SRGLetterboxService : NSObject <AVPictureInPictureControllerDelegate>

/**
 *  The singleton instance
 */
+ (SRGLetterboxService *)sharedService;

/**
 *  The controller responsible for main playback
 */
@property (nonatomic, nullable) SRGLetterboxController *controller;

@end

/**
 *  Picture in picture support. Implement `SRGLetterboxPictureInPictureDelegate` methods to integrate Letterbox picture in picture
 *  support within your application
 */
@interface SRGLetterboxService (PictureInPicture)

/**
 *  Picture in picture delegate. Picture in picture won't be available if not set
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

/**
 *  Return YES iff picture in picture is active
 */
@property (nonatomic, readonly, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

@end

/**
 *  Mirroring
 */
@interface SRGLetterboxService (Mirroring)

/**
 *  If set to `YES`, the Letterbox player is mirrored as is when an external screen is connected, without switching to
 *  full-screen playback on this external screen. This is especially handy if you need to be able to show the player
 *  as is on scren, e.g. for presentation purposes
 *
 *  Default is `NO`
 */
@property (nonatomic, getter=isMirroredOnExternalScreen) BOOL mirroredOnExternalScreen;

@end

@interface SRGLetterboxService (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
