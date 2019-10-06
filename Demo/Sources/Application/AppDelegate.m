//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "DemosViewController.h"
#import "SettingsViewController.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <AppCenter/AppCenter.h>
#import <AppCenterCrashes/AppCenterCrashes.h>
#import <AppCenterDistribute/AppCenterDistribute.h>

static __attribute__((constructor)) void ApplicationInit(void)
{
    NSString *contentProtectionFrameworkPath = [NSBundle.mainBundle pathForResource:@"SRGContentProtection" ofType:@"framework" inDirectory:@"Frameworks"];
    NSBundle *contentProtectionFramework = [NSBundle bundleWithPath:contentProtectionFrameworkPath];
    [contentProtectionFramework loadAndReturnError:NULL];
}

@interface AppDelegate ()

@property (nonatomic, weak) DemosViewController *demosViewController;

@end

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.blackColor;
    [self.window makeKeyAndVisible];
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    application.accessibilityLanguage = @"en";
    
    [SRGNetworkActivityManagement enable];
    
#ifndef DEBUG
    [self setupAppcenter];
#endif
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       container:10
                                                                                             comScoreVirtualSite:@"rts-app-test-v"
                                                                                             netMetrixIdentifier:@"test"];
    configuration.centralized = YES;
    
    [[SRGAnalyticsTracker sharedTracker] startWithConfiguration:configuration];
    
    SRGLetterboxService.sharedService.mirroredOnExternalScreen = ApplicationSettingIsMirroredOnExternalScreen();
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:demosViewController];
    self.demosViewController = demosViewController;
    
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
            
            [self.demosViewController openModalPlayerWithURN:mediaURN serviceURL:serviceURL updateInterval:nil];
            return YES;
        }
        
        return NO;
    }
    
    return NO;
}

#pragma mark Helpers

- (void)setupAppcenter
{
    [MSCrashes setUserConfirmationHandler:^BOOL(NSArray<MSErrorReport *> * _Nonnull errorReports) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sorry about that!", nil)
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
    
    NSString *appCenterSecret = [NSBundle.mainBundle objectForInfoDictionaryKey:@"AppCenterSecret"];
    [MSAppCenter start:appCenterSecret withServices:@[ MSCrashes.class, MSDistribute.class ]];
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
