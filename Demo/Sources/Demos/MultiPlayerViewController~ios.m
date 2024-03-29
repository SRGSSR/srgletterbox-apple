//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MultiPlayerViewController.h"

#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"
#import "UIApplication+LetterboxDemo.h"
#import "UIWindow+LetterboxDemo.h"

@import SRGAnalytics;

@interface MultiPlayerViewController ()

@property (nonatomic, copy) NSString *URN;
@property (nonatomic, copy) NSString *URN1;
@property (nonatomic, copy) NSString *URN2;

@property (nonatomic, getter=isUserInterfaceAlwaysHidden) BOOL userInterfaceAlwaysHidden;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet SRGLetterboxView *smallLetterboxView1;
@property (nonatomic, weak) IBOutlet SRGLetterboxView *smallLetterboxView2;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;
@property (nonatomic) IBOutlet SRGLetterboxController *smallLetterboxController1;
@property (nonatomic) IBOutlet SRGLetterboxController *smallLetterboxController2;

@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@end

@implementation MultiPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(NSString *)URN URN1:(NSString *)URN1 URN2:(NSString *)URN2 userInterfaceAlwaysHidden:(BOOL)userInterfaceAlwaysHidden
{
    id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate = SRGLetterboxService.sharedService.pictureInPictureDelegate;
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if ([pictureInPictureDelegate isKindOfClass:self.class]) {
        MultiPlayerViewController *multiplayerViewController = (MultiPlayerViewController *)pictureInPictureDelegate;
        if ([multiplayerViewController.URN isEqual:URN] && [multiplayerViewController.URN1 isEqual:URN1] && [multiplayerViewController.URN2 isEqual:URN2]) {
            return multiplayerViewController;
        }
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LetterboxDemoResourceNameForUIClass(self.class) bundle:nil];
    MultiPlayerViewController *multiPlayerViewController = [storyboard instantiateInitialViewController];
    
    multiPlayerViewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
    multiPlayerViewController.letterboxController.globalParameters = ApplicationSettingGlobalParameters();
    multiPlayerViewController.letterboxController.backgroundVideoPlaybackEnabled = ApplicationSettingIsBackgroundVideoPlaybackEnabled();
    
    multiPlayerViewController.smallLetterboxController1.serviceURL = ApplicationSettingServiceURL();
    multiPlayerViewController.smallLetterboxController1.globalParameters = ApplicationSettingGlobalParameters();
    multiPlayerViewController.smallLetterboxController1.backgroundVideoPlaybackEnabled = ApplicationSettingIsBackgroundVideoPlaybackEnabled();
    
    multiPlayerViewController.smallLetterboxController2.serviceURL = ApplicationSettingServiceURL();
    multiPlayerViewController.smallLetterboxController2.globalParameters = ApplicationSettingGlobalParameters();
    multiPlayerViewController.smallLetterboxController2.backgroundVideoPlaybackEnabled = ApplicationSettingIsBackgroundVideoPlaybackEnabled();
    
    multiPlayerViewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    multiPlayerViewController.smallLetterboxController1.updateInterval = ApplicationSettingUpdateInterval();
    multiPlayerViewController.smallLetterboxController2.updateInterval = ApplicationSettingUpdateInterval();
    
    multiPlayerViewController.URN = URN;
    multiPlayerViewController.URN1 = URN1;
    multiPlayerViewController.URN2 = URN2;
    multiPlayerViewController.userInterfaceAlwaysHidden = userInterfaceAlwaysHidden;
    
    return multiPlayerViewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.closeButton.accessibilityLabel = NSLocalizedString(@"Close", nil);
    
    [SRGLetterboxService.sharedService enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    self.smallLetterboxController1.muted = YES;
    self.smallLetterboxController1.tracked = NO;
    self.smallLetterboxController1.resumesAfterRouteBecomesUnavailable = YES;
    
    self.smallLetterboxController2.muted = YES;
    self.smallLetterboxController2.tracked = NO;
    self.smallLetterboxController2.resumesAfterRouteBecomesUnavailable = YES;
    
    [self.smallLetterboxView1 setUserInterfaceHidden:self.userInterfaceAlwaysHidden animated:NO togglable:! self.userInterfaceAlwaysHidden];
    [self.smallLetterboxView2 setUserInterfaceHidden:self.userInterfaceAlwaysHidden animated:NO togglable:! self.userInterfaceAlwaysHidden];
    
    UIGestureRecognizer *tapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchToStream1:)];
    [self.smallLetterboxView1 addGestureRecognizer:tapGestureRecognizer1];
    
    UIGestureRecognizer *tapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchToStream2:)];
    [self.smallLetterboxView2 addGestureRecognizer:tapGestureRecognizer2];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    
    if (! self.letterboxController.pictureInPictureActive) {
        SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
        settings.standalone = ApplicationSettingStandalone();
        settings.quality = ApplicationSettingPreferredQuality();
        
        if (self.URN) {
            [self.letterboxController playURN:self.URN atPosition:nil withPreferredSettings:settings];
        }
        
        if (self.URN1) {
            [self.smallLetterboxController1 playURN:self.URN1 atPosition:nil withPreferredSettings:settings];
        }
        
        if (self.URN2) {
            [self.smallLetterboxController2 playURN:self.URN2 atPosition:nil withPreferredSettings:settings];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        if (! self.letterboxController.pictureInPictureActive) {
            [SRGLetterboxService.sharedService disableForController:self.letterboxController];
        }
    }
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return @"Multi Player";
}

- (NSString *)srg_pageViewType
{
    return @"Detail";
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topViewController = UIApplication.sharedApplication.letterbox_demo_mainWindow.letterbox_demo_topViewController;
    return topViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = UIApplication.sharedApplication.letterbox_demo_mainWindow.letterbox_demo_topViewController;
    [topViewController presentViewController:self animated:YES completion:^{
        completionHandler(YES);
    }];
}

- (void)letterboxDidStartPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackEventWithName:@"pip_start"];
}

- (void)letterboxDidEndPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackEventWithName:@"pip_end"];
}

- (void)letterboxDidStopPlaybackFromPictureInPicture
{
    [SRGLetterboxService.sharedService disableForController:self.letterboxController];
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat aspectRatio, CGFloat heightOffset) {
        self.letterboxAspectRatioConstraint = [self.letterboxAspectRatioConstraint srg_replacementConstraintWithMultiplier:fminf(1.f / aspectRatio, 1.f)
                                                                                                                  constant:heightOffset];
        self.closeButton.alpha = (minimal || ! hidden) ? 1.f : 0.f;
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Gesture recognizers

- (void)switchToStream1:(UIGestureRecognizer *)gestureRecognizer
{
    // Swap controllers
    SRGLetterboxController *tempLetterboxController = self.letterboxController;
    
    self.letterboxController = self.smallLetterboxController1;
    self.letterboxView.controller = self.smallLetterboxController1;
    
    self.smallLetterboxController1 = tempLetterboxController;
    self.smallLetterboxView1.controller = tempLetterboxController;
    
    self.letterboxController.muted = NO;
    self.letterboxController.tracked = YES;
    self.letterboxController.resumesAfterRouteBecomesUnavailable = NO;
    
    [SRGLetterboxService.sharedService enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    self.smallLetterboxController1.muted = YES;
    self.smallLetterboxController1.tracked = NO;
    self.smallLetterboxController1.resumesAfterRouteBecomesUnavailable = YES;
}

- (void)switchToStream2:(UIGestureRecognizer *)gestureRecognizer
{
    // Swap controllers
    SRGLetterboxController *tempLetterboxController = self.letterboxController;
    
    self.letterboxController = self.smallLetterboxController2;
    self.letterboxView.controller = self.smallLetterboxController2;
    
    self.smallLetterboxController2 = tempLetterboxController;
    self.smallLetterboxView2.controller = tempLetterboxController;
    
    self.letterboxController.muted = NO;
    self.letterboxController.tracked = YES;
    self.letterboxController.resumesAfterRouteBecomesUnavailable = NO;
    
    [SRGLetterboxService.sharedService enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    self.smallLetterboxController2.muted = YES;
    self.smallLetterboxController2.tracked = NO;
    self.smallLetterboxController2.resumesAfterRouteBecomesUnavailable = YES;
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self.letterboxController play];
    [self.smallLetterboxController1 play];
    [self.smallLetterboxController2 play];
}

@end
