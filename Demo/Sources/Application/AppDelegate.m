//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "Application.h"
#import "SettingsViewController.h"

@import AppCenter;
@import AppCenterCrashes;
#if TARGET_OS_IOS
@import AppCenterDistribute;
#endif
@import SRGAnalytics;
@import SRGLetterbox;
@import SRGNetwork;

static __attribute__((constructor)) void ApplicationInit(void)
{
    NSString *contentProtectionFrameworkPath = [NSBundle.mainBundle pathForResource:@"SRGContentProtection" ofType:@"framework" inDirectory:@"Frameworks"];
    NSBundle *contentProtectionFramework = [NSBundle bundleWithPath:contentProtectionFrameworkPath];
    [contentProtectionFramework loadAndReturnError:NULL];
}

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    application.accessibilityLanguage = @"en";
        
#ifndef DEBUG
    [self setupAppCenter];
#endif
    
#if TARGET_OS_IOS
    [SRGNetworkActivityManagement enable];
    
    SRGLetterboxService.sharedService.mirroredOnExternalScreen = ApplicationSettingIsMirroredOnExternalScreen();
#endif
    
    // Use a debug source key since there will never be any public App Store version of this demo application.
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       sourceKey:@"39ae8f94-595c-4ca4-81f7-fb7748bd3f04"
                                                                                                        siteName:@"rts-app-test-v"];
    configuration.centralized = YES;
    
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
    
    if (@available(iOS 13, tvOS 13, *)) {}
    else {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        [self.window makeKeyAndVisible];
        self.window.rootViewController = ApplicationRootViewController();
    }
    return YES;
}

#pragma mark Helpers

- (void)setupAppCenter
{
    NSString *appCenterSecret = [NSBundle.mainBundle objectForInfoDictionaryKey:@"AppCenterSecret"];
    if (appCenterSecret.length == 0) {
        return;
    }
    
    [MSACCrashes setUserConfirmationHandler:^BOOL(NSArray<MSACErrorReport *> * _Nonnull errorReports) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"The application unexpectedly quit", nil)
                                                                                 message:NSLocalizedString(@"Do you want to send an anonymous crash report so we can fix the issue?", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Don't send", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationSend];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationSend];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Always send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationSend];
        }]];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return YES;
    }];
    
#if defined(APPCENTER)
    MSACDistribute.updateTrack = MSACUpdateTrackPrivate;
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class, MSACDistribute.class ]];
#else
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class ]];
#endif
}

@end
