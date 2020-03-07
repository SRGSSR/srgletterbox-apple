//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "StandalonePlayerViewController.h"

#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"
#import "UIWindow+LetterboxDemo.h"

#import <SRGAnalytics/SRGAnalytics.h>

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

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.letterbox_demo_topViewController;
    return topViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.letterbox_demo_topViewController;
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
    [SRGLetterboxService.sharedService disableForController:self.letterboxController];
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)updateWithAspectRatio:(CGFloat)aspectRatio
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.letterboxAspectRatioConstraint.firstItem
                                                                  attribute:self.letterboxAspectRatioConstraint.firstAttribute
                                                                  relatedBy:self.letterboxAspectRatioConstraint.relation
                                                                     toItem:self.letterboxAspectRatioConstraint.secondItem
                                                                  attribute:self.letterboxAspectRatioConstraint.secondAttribute
                                                                 multiplier:1.f / aspectRatio
                                                                   constant:self.letterboxAspectRatioConstraint.constant];
    [NSLayoutConstraint deactivateConstraints:@[ self.letterboxAspectRatioConstraint ]];
    [NSLayoutConstraint activateConstraints:@[ constraint ]];
    
    self.letterboxAspectRatioConstraint = constraint;
}

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat aspectRatio, CGFloat heightOffset) {
        self.closeButton.alpha = (minimal || ! hidden) ? 1.f : 0.f;
        [self updateWithAspectRatio:aspectRatio];
        self.letterboxAspectRatioConstraint.constant = heightOffset;
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
