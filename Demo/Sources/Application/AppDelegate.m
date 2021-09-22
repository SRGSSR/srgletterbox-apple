//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "Application.h"
#import "ServerSettings.h"
#import "SettingsViewController.h"
#import "UIViewController+LetterboxDemo.h"

@import AppCenter;
@import AppCenterCrashes;
#if TARGET_OS_IOS
@import AppCenterDistribute;
#endif
@import libextobjc;
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
    
    // Use test setup and pre-production mode since there will never be any public App Store version of this demo application.
    // This prevents tvOS builds delivered with TestFlight from sending production data.
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                                        siteName:@"rts-app-test-v"];
    configuration.centralized = YES;
    configuration.environmentMode = SRGAnalyticsEnvironmentModePreProduction;
    
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
    
    if (@available(iOS 13, tvOS 13, *)) {}
    else {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        [self.window makeKeyAndVisible];
        self.window.rootViewController = ApplicationRootViewController();
    }
    return YES;
}

// Open [scheme]://open?media=[media_urn] (optional &server=[server_name])
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)URL options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    if ([URLComponents.host.lowercaseString isEqualToString:@"media"]) {
        NSString *mediaURN = URLComponents.path.lastPathComponent;
        if (mediaURN) {
            NSURL *serviceURL = nil;
            NSString *server = [self valueFromURLComponents:URLComponents withParameterName:@"server"];
            if (server) {
                serviceURL = LetterboxDemoServiceURLForKey(server);
            }
      
            [self.window.rootViewController openPlayerWithURN:mediaURN serviceURL:serviceURL];
            return YES;
        }
        return NO;
    }
    return NO;
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
    
#if TARGET_OS_IOS
    MSACDistribute.updateTrack = MSACUpdateTrackPrivate;
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class, MSACDistribute.class ]];
#else
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class ]];
#endif
}

#pragma mark Custom URL scheme support

- (NSString *)valueFromURLComponents:(NSURLComponents *)URLComponents withParameterName:(NSString *)parameterName
{
    NSParameterAssert(URLComponents);
    NSParameterAssert(parameterName);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(NSURLQueryItem.new, name), parameterName];
    NSURLQueryItem *queryItem = [URLComponents.queryItems filteredArrayUsingPredicate:predicate].firstObject;
    if (! queryItem) {
        return nil;
    }
    
    return queryItem.value;
}

@end
