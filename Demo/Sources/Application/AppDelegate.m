//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "ListsViewController.h"
#import "MediasViewController.h"
#import "MiscellaneousViewController.h"
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
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    application.accessibilityLanguage = @"en";
        
#ifndef DEBUG
    [self setupAppCenter];
#endif
    
    // Use test setup and pre-production mode since there will never be any public App Store version of this demo application.
    // This prevents tvOS builds delivered with TestFlight from sending production data.
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                                        siteName:@"rts-app-test-v"];
    configuration.centralized = YES;
    configuration.environmentMode = SRGAnalyticsEnvironmentModePreProduction;
    
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
    
    MediasViewController *mediasViewController = [[MediasViewController alloc] init];
    ListsViewController *listsViewController = [[ListsViewController alloc] init];
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    
#if TARGET_OS_IOS
    [SRGNetworkActivityManagement enable];
        
    SRGLetterboxService.sharedService.mirroredOnExternalScreen = ApplicationSettingIsMirroredOnExternalScreen();
    
    UINavigationController *mediasNavigationViewController = [[UINavigationController alloc] initWithRootViewController:mediasViewController];
    mediasNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Medias", nil) image:[UIImage imageNamed:@"medias"] tag:0];
    
    UINavigationController *listsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:listsViewController];
    listsNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Lists", nil) image:[UIImage imageNamed:@"lists"] tag:1];
    
    MiscellaneousViewController *miscellaneousViewController = [[MiscellaneousViewController alloc] init];
    UINavigationController *miscellaneousNavigationViewController = [[UINavigationController alloc] initWithRootViewController:miscellaneousViewController];
    miscellaneousNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Miscellaneous", nil) image:[UIImage imageNamed:@"miscellaneous"] tag:2];
    
    UINavigationController *settingsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) image:[UIImage imageNamed:@"settings"] tag:3];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ mediasNavigationViewController, listsNavigationViewController, miscellaneousNavigationViewController, settingsNavigationViewController ];
    self.window.rootViewController = tabBarController;
#else
    mediasViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Medias", nil) image:nil tag:0];
    listsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Lists", nil) image:nil tag:1];
    settingsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) image:nil tag:2];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ mediasViewController, listsViewController, settingsViewController ];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
#endif
    
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
