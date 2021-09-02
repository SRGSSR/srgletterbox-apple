//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Application.h"

#import "ListsViewController.h"
#import "MediasViewController.h"
#import "MiscellaneousViewController.h"
#import "SettingsViewController.h"

UIViewController *ApplicationRootViewController(void)
{
    MediasViewController *mediasViewController = [[MediasViewController alloc] init];
    ListsViewController *listsViewController = [[ListsViewController alloc] init];
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    
#if TARGET_OS_IOS
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
    return tabBarController;
#else
    mediasViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Medias", nil) image:nil tag:0];
    listsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Lists", nil) image:nil tag:1];
    settingsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil) image:nil tag:2];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[ mediasViewController, listsViewController, settingsViewController ];
    
    return [[UINavigationController alloc] initWithRootViewController:tabBarController];
#endif
}
