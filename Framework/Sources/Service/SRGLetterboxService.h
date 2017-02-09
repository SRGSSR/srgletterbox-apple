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
 * 
 *  @discussion The delegate is retained
 */
@property (nonatomic, nullable) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

/**
 *  Stop picture in picture. If `restoreUserInterface` is set to NO, the restoration delegate methods will not be called
 */
- (void)stopPictureInPictureRestoreUserInterface:(BOOL)restoreUserInterface;

@end

/**
 *  Mirroring
 */
@interface SRGLetterboxService (Airplay)

/**
 *  If set to `YES`, the Letterbox player never switches to full-screen playback on this external screen. This is especially
 *  handy to mirror your application for presentation purposes
 *
 *  Default is `NO`
 */
@property (nonatomic, getter=isMirroredOnExternalScreen) BOOL mirroredOnExternalScreen;

@end

@interface SRGLetterboxService (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
