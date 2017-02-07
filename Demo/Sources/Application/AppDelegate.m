//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "DemosViewController.h"
#import "ModalPlayerViewController.h"
#import "SimplePlayerViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGDataProvider/SRGDataProvider.h>

#import <HockeySDK/HockeySDK.h>

@interface AppDelegate ()

@property (nonatomic) Class restorationClass;

@property (nonatomic, readonly) UINavigationController *navigationController;
@property (nonatomic, readonly) UIViewController *topPresentedViewController;

@end

@implementation AppDelegate

#pragma mark Getters and setters

- (UINavigationController *)navigationController
{
    return (UINavigationController *)self.window.rootViewController;
}

- (UIViewController *)topPresentedViewController
{
    UIViewController *topPresentedViewController = self.window.rootViewController;
    while (topPresentedViewController.presentedViewController) {
        topPresentedViewController = topPresentedViewController.presentedViewController;
    }
    return topPresentedViewController;
}

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierTEST
                                                     comScoreVirtualSite:@"app-test-v"
                                                     netMetrixIdentifier:@"test"];
    
    [SRGLetterboxService sharedService].pictureInPictureDelegate = self;
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:demosViewController];
    
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"7bf489539f6e44739133ae456c41dc2c"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    return YES;
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    return ! [self.topPresentedViewController isKindOfClass:[ModalPlayerViewController class]]
        && ! [self.navigationController.topViewController isKindOfClass:[SimplePlayerViewController class]];
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (self.restorationClass == [ModalPlayerViewController class]) {
        ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] init];
        [self.topPresentedViewController presentViewController:playerViewController animated:YES completion:^{
            completionHandler(YES);
        }];
    }
    else if (self.restorationClass == [SimplePlayerViewController class]) {
        SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] init];
        [self.navigationController pushViewController:playerViewController animated:YES];
        completionHandler(YES);
        // FIXME: Call completion handler at the end of the transition animation!!
    }
}

- (void)letterboxDidStartPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"pip_start"];
    
    if ([self.topPresentedViewController isKindOfClass:[ModalPlayerViewController class]]) {
        self.restorationClass = [ModalPlayerViewController class];
        [self.topPresentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else if ([self.navigationController.topViewController isKindOfClass:[SimplePlayerViewController class]]) {
        self.restorationClass = [SimplePlayerViewController class];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)letterboxDidStopPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"pip_stop"];
    self.restorationClass = Nil;
}

@end
