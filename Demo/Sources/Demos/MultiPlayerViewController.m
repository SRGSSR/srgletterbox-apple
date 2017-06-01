//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MultiPlayerViewController.h"

#import "UIWindow+LetterboxDemo.h"
#import "NSBundle+LetterboxDemo.h"

#import <SRGAnalytics/SRGAnalytics.h>

@interface MultiPlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) SRGMediaURN *URN1;
@property (nonatomic) SRGMediaURN *URN2;

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

- (instancetype)initWithURN:(nullable SRGMediaURN *)URN URN1:(nullable SRGMediaURN *)URN1 URN2:(nullable SRGMediaURN *)URN2 userInterfaceAlwaysHidden:(BOOL)userInterfaceAlwaysHidden
{
    id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate = [SRGLetterboxService sharedService].pictureInPictureDelegate;
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if ([pictureInPictureDelegate isKindOfClass:[self class]]) {
        MultiPlayerViewController *multiplayerViewController = (MultiPlayerViewController *)pictureInPictureDelegate;
        if ([multiplayerViewController.URN isEqual:URN] && [multiplayerViewController.URN1 isEqual:URN1] && [multiplayerViewController.URN2 isEqual:URN2]) {
            return multiplayerViewController;
        }
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    MultiPlayerViewController *multiPlayerViewController = [storyboard instantiateInitialViewController];
    
    multiPlayerViewController.URN = URN;
    multiPlayerViewController.URN1 = URN1;
    multiPlayerViewController.URN2 = URN2;
    multiPlayerViewController.userInterfaceAlwaysHidden = userInterfaceAlwaysHidden;
    
    return multiPlayerViewController;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.closeButton.accessibilityLabel = SRGLetterboxDemoAccessibilityLocalizedString(@"Close", @"Close button on player view");
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    if (! self.letterboxController.pictureInPictureActive) {
        [self.letterboxController playURN:self.URN];
        [self.smallLetterboxController1 playURN:self.URN1];
        [self.smallLetterboxController2 playURN:self.URN2];
    }
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
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"pip_start"];
}

- (void)letterboxDidEndPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"pip_end"];
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
        self.closeButton.alpha = (hidden && ! self.letterboxController.error) ? 0.f : 1.f;
        self.letterboxAspectRatioConstraint.constant = heightOffset;
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
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
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
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
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
