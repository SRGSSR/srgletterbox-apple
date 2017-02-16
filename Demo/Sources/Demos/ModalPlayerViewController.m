//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalPlayerViewController.h"

#import "UIWindow+LetterboxDemo.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>

static const UILayoutPriority LetterboxViewConstraintLessPriority = 850;
static const UILayoutPriority LetterboxViewConstraintMorePriority = 950;

@interface ModalPlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

// Switching to and from full-screen is made by adjusting the priority / constance of a constraint of the letterbox
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxLeadingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterbox169Constraint;

@property (nonatomic, getter=isTransitioningToFullScreen) BOOL wantsFullScreen;

@end

@implementation ModalPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN
{
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if ([service.pictureInPictureDelegate isKindOfClass:[self class]] && [service.controller.URN isEqual:URN]) {
        return (ModalPlayerViewController *)service.pictureInPictureDelegate;
    }
    // Otherwise instantiate a fresh new one
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
        ModalPlayerViewController *viewController = [storyboard instantiateInitialViewController];
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
    
    self.letterboxController.streamAvailabilityCheckInterval = 10.;
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    // Start with a hidden interface
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        [self.letterboxController playURN:self.URN];
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

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return self.wantsFullScreen;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topPresentedViewController = [UIApplication sharedApplication].keyWindow.topPresentedViewController;
    return topPresentedViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topPresentedViewController = [UIApplication sharedApplication].keyWindow.topPresentedViewController;
    [topPresentedViewController presentViewController:self animated:YES completion:^{
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
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden) {
        self.closeButton.alpha = (hidden && ! self.letterboxController.error) ? 0.f : 1.f;
    } completion:nil];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(nonnull void (^)(BOOL))completionHandler
{
    [self.view layoutIfNeeded];
    
    void (^animations)(void) = ^{
        if (fullScreen) {
            self.letterboxLeadingConstraint.constant = 0.f;
            self.letterboxTrailingConstraint.constant = 0.f;
            self.letterboxTopConstraint.constant = 0.f;
            
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintMorePriority;
            self.letterbox169Constraint.priority = LetterboxViewConstraintLessPriority;
        }
        else {
            // Tweak the margins for iPhone landscape layout
            if ((self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
                self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) ||
                (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
                 self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)) {
                self.letterboxLeadingConstraint.constant = 32.f;
                self.letterboxTrailingConstraint.constant = 32.f;
            }
            else {
                self.letterboxLeadingConstraint.constant = 16.f;
                self.letterboxTrailingConstraint.constant = 16.f;
            }
            self.letterboxTopConstraint.constant = 5.f;
            
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintLessPriority;
            self.letterbox169Constraint.priority = LetterboxViewConstraintMorePriority;
        }
        
        [self setNeedsStatusBarAppearanceUpdate];
        [self.view layoutIfNeeded];
    };
    
    self.wantsFullScreen = fullScreen;
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            animations();
        } completion:completionHandler];
    }
    else {
        animations();
        completionHandler(YES);
    }
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)hideControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:YES animated:YES togglable:YES];
}

- (IBAction)showControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:NO animated:YES togglable:YES];
}

- (IBAction)forceHideControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:YES animated:YES togglable:NO];
}

- (IBAction)forceShowControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:NO animated:YES togglable:NO];
}

- (IBAction)fullScreen:(id)sender
{
    [self.letterboxView setFullScreen:YES animated:YES];
}

@end
