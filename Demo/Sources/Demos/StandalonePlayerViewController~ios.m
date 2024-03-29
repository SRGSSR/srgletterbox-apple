//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "StandalonePlayerViewController.h"

#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"
#import "UIApplication+LetterboxDemo.h"
#import "UIWindow+LetterboxDemo.h"

@import SRGAnalytics;

@interface StandalonePlayerViewController ()

@property (nonatomic, copy) NSString *URN;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UISwitch *serviceEnabled;
@property (nonatomic, weak) IBOutlet UISwitch *nowPlayingInfoAndCommandsEnabled;
@property (nonatomic, weak) IBOutlet UISwitch *mirroredSwitch;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@end

@implementation StandalonePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(NSString *)URN
{
    SRGLetterboxService *service = SRGLetterboxService.sharedService;
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if ([service.pictureInPictureDelegate isKindOfClass:self.class] && [service.controller.URN isEqual:URN]) {
        return (StandalonePlayerViewController *)service.pictureInPictureDelegate;
    }
    // Otherwise instantiate a fresh new one
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LetterboxDemoResourceNameForUIClass(self.class) bundle:nil];
        StandalonePlayerViewController *viewController = [storyboard instantiateInitialViewController];
        
        viewController.URN = URN;
        
        viewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
        viewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
        viewController.letterboxController.globalHeaders = ApplicationSettingGlobalParameters();
        viewController.letterboxController.backgroundVideoPlaybackEnabled = ApplicationSettingIsBackgroundVideoPlaybackEnabled();
        
        return viewController;
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.closeButton.accessibilityLabel = NSLocalizedString(@"Close", nil);
    
    self.serviceEnabled.on = [SRGLetterboxService.sharedService.controller isEqual:self.letterboxController];
    self.nowPlayingInfoAndCommandsEnabled.on = SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled;
    self.mirroredSwitch.on = ApplicationSettingIsMirroredOnExternalScreen();
    
    if (self.URN) {
        SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
        settings.standalone = ApplicationSettingStandalone();
        settings.quality = ApplicationSettingPreferredQuality();
        
        [self.letterboxController playURN:self.URN atPosition:nil withPreferredSettings:settings];
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
    return @"Standalone Player";
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
        self.closeButton.alpha = (minimal || ! hidden) ? 1.f : 0.f;
        self.letterboxAspectRatioConstraint = [self.letterboxAspectRatioConstraint srg_replacementConstraintWithMultiplier:fminf(1.f / aspectRatio, 1.f)
                                                                                                                  constant:heightOffset];
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleServiceEnabled:(id)sender
{
    if ([SRGLetterboxService.sharedService.controller isEqual:self.letterboxController]) {
        [SRGLetterboxService.sharedService disableForController:self.letterboxController];
    }
    else {
        [SRGLetterboxService.sharedService enableWithController:self.letterboxController pictureInPictureDelegate:self];
    }
}

- (IBAction)toggleNowPlayingInfoAndCommands:(id)sender
{
    SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled = ! SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled;
}

- (IBAction)toggleMirrored:(id)sender
{
    ApplicationSettingSetMirroredOnExternalScreen(! ApplicationSettingIsMirroredOnExternalScreen());
}

@end
