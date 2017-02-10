//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Background services (Airplay and picture in picture)
 */
@interface SRGLetterboxBackgroundServices : NSObject

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
+ (void)enableWithController:(SRGLetterboxController *)controller
    pictureInPictureDelegate:(nullable id<SRGLetterboxPictureInPictureDelegate>)pictureInPictureDelegate;

/**
 *  Disable background services
 */
+ (void)disable;

/**
 *  The controller currently enabled for background services, if any
 */
@property (class, nonatomic, readonly, nullable) SRGLetterboxController *controller;

/**
 *  If set to `YES`, the Letterbox player never switches to full-screen playback on this external screen. This is especially
 *  handy to mirror your application for presentation purposes
 *
 *  Default is `NO`
 */
@property (class, nonatomic, getter=isMirroredOnExternalScreen) BOOL mirroredOnExternalScreen;

@end

NS_ASSUME_NONNULL_END
