//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBackgroundServices.h"

#import "SRGLetterboxService.h"

static BOOL s_disablingAudioServices = NO;

@implementation SRGLetterboxBackgroundServices

#pragma mark Class methods

+ (void)startWithController:(SRGLetterboxController *)controller pictureInPictureDelegate:(id<SRGLetterboxPictureInPictureDelegate>)pictureInPictureDelegate
{
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSArray<NSString *> *backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
        if (! [backgroundModes containsObject:@"audio"]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"You must enable the 'Audio, Airplay, and Picture in Picture' flag of your target background modes (under the Capabilities tab) before attempting to use the Letterbox service"
                                         userInfo:nil];
        }
    });
    
    [SRGLetterboxService sharedService].controller = controller;
    [SRGLetterboxService sharedService].pictureInPictureDelegate = pictureInPictureDelegate;
    
    s_disablingAudioServices = NO;
    
    // Required for Airplay, picture in picture and control center to work correctly
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

+ (void)stop
{
    [SRGLetterboxService sharedService].controller = nil;
    [SRGLetterboxService sharedService].pictureInPictureDelegate = nil;
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // Cancel after some delay to let running audio processes gently terminate (otherwise audio hiccups will be
    // noticeable because of the audio session category change)
    s_disablingAudioServices = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Since dispatch_after cannot be cancelled, deal with the possibility that services are enabled again while
        // the the block has not been executed yet
        if (! s_disablingAudioServices) {
            return;
        }
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    });
}

+ (SRGLetterboxController *)controller
{
    return [SRGLetterboxService sharedService].controller;
}

+ (void)setMirroredOnExternalScreen:(BOOL)mirroredOnExternalScreen
{
    [SRGLetterboxService sharedService].mirroredOnExternalScreen = YES;
}

+ (BOOL)isMirroredOnExternalScreen
{
    return [SRGLetterboxService sharedService].mirroredOnExternalScreen;
}

@end
