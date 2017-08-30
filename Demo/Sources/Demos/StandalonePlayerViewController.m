//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "StandalonePlayerViewController.h"

#import "SettingsViewController.h"
#import "UIWindow+LetterboxDemo.h"

#import <SRGAnalytics/SRGAnalytics.h>

@interface StandalonePlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UISwitch *mirroredSwitch;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@end

@implementation StandalonePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN
{
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if ([service.pictureInPictureDelegate isKindOfClass:[self class]] && [service.controller.URN isEqual:URN]) {
        return (StandalonePlayerViewController *)service.pictureInPictureDelegate;
    }
    // Otherwise instantiate a fresh new one
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
        StandalonePlayerViewController *viewController = [storyboard instantiateInitialViewController];
        viewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
        viewController.URN = URN;
        return viewController;
    }
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mirroredSwitch.on = ApplicationSettingIsMirroredOnExternalScreen();
    
    [self.letterboxController playURN:self.URN withChaptersOnly:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        if (! self.letterboxController.pictureInPictureActive) {
            [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
        }
    }
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.topViewController;
    return topViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.topViewController;
    [topViewController presentViewController:self animated:YES completion:^{
        completionHandler(YES);
    }];
}

- (void)letterboxDidStartPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithName:@"pip_start"];
}

- (void)letterboxDidEndPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithName:@"pip_end"];
}

- (void)letterboxDidStopPlaybackFromPictureInPicture
{
    [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, CGFloat heightOffset) {
        self.closeButton.alpha = (hidden && ! self.letterboxController.error && self.letterboxController.URN) ? 0.f : 1.f;
        self.letterboxAspectRatioConstraint.constant = heightOffset;
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)useForService:(id)sender
{
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
}

- (IBAction)resetService:(id)sender
{
    [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
}

- (IBAction)toggleMirrored:(id)sender
{
    ApplicationSettingSetMirroredOnExternalScreen(! ApplicationSettingIsMirroredOnExternalScreen());
}

@end
