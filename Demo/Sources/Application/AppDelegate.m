//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "MediaListsViewController.h"
#import "MediasViewController.h"
#import "MiscellaneousViewController.h"
#import "SettingsViewController.h"
#import "UIViewController+LetterboxDemo.h"

#import <AppCenter/AppCenter.h>
#import <AppCenterCrashes/AppCenterCrashes.h>
#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGLetterbox/SRGLetterbox.h>

#if TARGET_OS_IOS
#import <AppCenterDistribute/AppCenterDistribute.h>
#endif

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
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                             comScoreVirtualSite:@"rts-app-test-v"
                                                                                             netMetrixIdentifier:@"test"];
    configuration.centralized = YES;
    
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
    
#if TARGET_OS_IOS
    [SRGNetworkActivityManagement enable];
        
    SRGLetterboxService.sharedService.mirroredOnExternalScreen = ApplicationSettingIsMirroredOnExternalScreen();
#endif
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    
    UIViewController *viewController1 = [[MediasViewController alloc] init];
#if TARGET_OS_IOS
    viewController1 = [[UINavigationController alloc] initWithRootViewController:viewController1];
#endif
    viewController1.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Medias", nil) image:[UIImage imageNamed:@"medias"] tag:0];
    [viewControllers addObject:viewController1];
    
    UIViewController *viewController2 = [[MediaListsViewController alloc] init];
#if TARGET_OS_IOS
    viewController2 = [[UINavigationController alloc] initWithRootViewController:viewController2];
#endif
    viewController2.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Lists", nil) image:[UIImage imageNamed:@"lists"] tag:1];
    [viewControllers addObject:viewController2];
    
#if TARGET_OS_IOS
    MiscellaneousViewController *miscellaneousViewController = [[MiscellaneousViewController alloc] init];
    UINavigationController *miscellaneousNavigationViewController = [[UINavigationController alloc] initWithRootViewController:miscellaneousViewController];
    miscellaneousNavigationViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Miscellaneous", nil) image:[UIImage imageNamed:@"miscellaneous"] tag:2];
    [viewControllers addObject:miscellaneousNavigationViewController];
#endif
    
    UIViewController *viewController3 = [[SettingsViewController alloc] init];
#if TARGET_OS_IOS
    viewController3 = [[UINavigationController alloc] initWithRootViewController:viewController3];
#endif
    viewController3.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) image:[UIImage imageNamed:@"settings"] tag:3];
    [viewControllers addObject:viewController3];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = viewControllers.copy;
    self.window.rootViewController = tabBarController;
    
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
    
    [MSCrashes setUserConfirmationHandler:^BOOL(NSArray<MSErrorReport *> * _Nonnull errorReports) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"The application unexpectedly quit", nil)
                                                                                 message:NSLocalizedString(@"Do you want to send an anonymous crash report so we can fix the issue?", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Don't send", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Always send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
        }]];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return YES;
    }];
    
#if TARGET_OS_IOS
    [MSAppCenter start:appCenterSecret withServices:@[ MSCrashes.class, MSDistribute.class ]];
#else
    [MSAppCenter start:appCenterSecret withServices:@[ MSCrashes.class ]];
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
