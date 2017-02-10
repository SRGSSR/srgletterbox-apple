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
 *  Enable background services for the specified controller. Airplay is always enabled, but picture in picture will only
 *  be enabled if a corresponding delegate is provided. The delegate is retained. Usually this should be the view controller
 *  associated with picture in picture, so that you can restore it later in the exact same state as before picture in
 *  picture was entered
 *
 *  @discussion The 'Audio, Airplay, and Picture in Picture' flag of your target background modes must be enabled, otherwise
 *              this method will throw an exception. Note that enabling picture in picture does not guarantee that the
 *              functionality will be available on the device the application is run on
 */
+ (void)startWithController:(SRGLetterboxController *)controller
   pictureInPictureDelegate:(nullable id<SRGLetterboxPictureInPictureDelegate>)pictureInPictureDelegate;

/**
 *  Disable background services
 */
+ (void)stop;

/**
 *  The controller responsible for main playback
 */
@property (class, nonatomic, nullable) SRGLetterboxController *controller;

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
