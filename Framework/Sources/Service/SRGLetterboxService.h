//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

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
@interface SRGLetterboxService : NSObject

/**
 *  The singleton instance
 */
+ (SRGLetterboxService *)sharedService;

/**
 *  The controller responsible for main playback
 */
@property (nonatomic, readonly) SRGLetterboxController *controller;

/**
 *  Transfers playback from the specified existing controller to the service. The service media player controller
 *  is replaced
 */
- (void)resumeFromController:(SRGLetterboxController *)controller;

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
