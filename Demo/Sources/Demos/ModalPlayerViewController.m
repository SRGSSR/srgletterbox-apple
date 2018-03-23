//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalPlayerViewController.h"

#import "ModalTransition.h"
#import "SettingsViewController.h"
#import "UIWindow+LetterboxDemo.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>

@interface ModalPlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;
@property (nonatomic) BOOL chaptersOnly;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *nowLabel;
@property (nonatomic, weak) IBOutlet UILabel *nextLabel;

@property (nonatomic, weak) IBOutlet UISwitch *timelineSwitch;

@property (nonatomic, weak) IBOutlet UIView *sizeView;
@property (nonatomic, weak) IBOutlet UISlider *heightOffsetSlider;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *letterboxMarginConstraints;

@property (nonatomic) BOOL wantsFullScreen;

@property (nonatomic) NSMutableArray<SRGSubdivision *> *favoritedSubdivisions;

@property (nonatomic) ModalTransition *interactiveTransition;

@end

@implementation ModalPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN chaptersOnly:(BOOL)chaptersOnly serviceURL:(NSURL *)serviceURL updateInterval:(NSNumber *)updateInterval
{
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if (service.controller.pictureInPictureActive && [service.pictureInPictureDelegate isKindOfClass:[self class]] && [service.controller.URN isEqual:URN]) {
        return (ModalPlayerViewController *)service.pictureInPictureDelegate;
    }
    // Otherwise instantiate a fresh new one
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
        ModalPlayerViewController *viewController = [storyboard instantiateInitialViewController];

        viewController.URN = URN;
        viewController.chaptersOnly = chaptersOnly;
        viewController.favoritedSubdivisions = [NSMutableArray array];

        viewController.letterboxController.serviceURL = serviceURL ?: ApplicationSettingServiceURL();
        viewController.letterboxController.updateInterval = updateInterval ? updateInterval.doubleValue : ApplicationSettingUpdateInterval();
        viewController.letterboxController.globalHeaders = ApplicationSettingGlobalHeaders();
        
        return viewController;
    }
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark Getters and setters

- (NSTimeInterval)updateInterval
{
    return self.letterboxController.updateInterval;
}

- (void)setUpdateInterval:(NSTimeInterval)updateInterval
{
    self.letterboxController.updateInterval = updateInterval;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.closeButton.accessibilityLabel = NSLocalizedString(@"Close", @"Close button label");
    
    self.timelineSwitch.enabled = ! self.letterboxView.timelineAlwaysHidden;
    
    // Use custom modal transition
    self.transitioningDelegate = self;
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    // Always display the full-screen interface in landscape orientation
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    BOOL isLandscape = UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation) ? UIDeviceOrientationIsLandscape(deviceOrientation) : UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    [self.letterboxView setFullScreen:isLandscape animated:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(metadataDidChange:)
                                                 name:SRGLetterboxMetadataDidChangeNotification
                                               object:self.letterboxController];
    
    self.letterboxController.contentURLOverridingBlock = ^(SRGMediaURN * _Nonnull URN) {
        return [URN isEqual:[SRGMediaURN mediaURNWithString:@"urn:rts:video:8806790"]] ? [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"] : nil;
    };
    
    if (self.URN) {
        [self.letterboxController playURN:self.URN withChaptersOnly:self.chaptersOnly];
    }
    
    // Start with a hidden interface. Performed after a URN has been assigned so that no UI is visible at all
    // initially (see -letterboxViewWillAnimateUserInterface: implementation)
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
    
    [self reloadData];
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

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        BOOL isLandscape = (size.width > size.height);
        [self.letterboxView setFullScreen:isLandscape animated:NO];
    } completion:nil];
}

#pragma mark Home indicator

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return self.letterboxView.fullScreen && self.letterboxView.userInterfaceHidden;
}

#pragma mark Data

- (void)reloadData
{
    [self reloadDataOverriddenWithMedia:nil];
}

- (void)reloadDataOverriddenWithMedia:(SRGMedia *)media
{
    if (! media) {
        media = self.letterboxController.subdivisionMedia;
    }
    
    self.titleLabel.text = media.title;
    
    SRGChannel *channel = self.letterboxController.channel;
    self.nowLabel.text = channel.currentProgram.title ? [NSString stringWithFormat:NSLocalizedString(@"Now: %@", nil), channel.currentProgram.title] : nil;
    self.nextLabel.text = channel.nextProgram.title ? [NSString stringWithFormat:NSLocalizedString(@"Next: %@", nil), channel.nextProgram.title] : nil;
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
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat heightOffset) {
        self.letterboxAspectRatioConstraint.constant = heightOffset + self.heightOffsetSlider.value;
        self.closeButton.alpha = (minimal || ! hidden) ? 1.f : 0.f;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (@available(iOS 11, *)) {
            [self setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
    }];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didScrollWithSubdivision:(SRGSubdivision *)subdivision time:(CMTime)time interactive:(BOOL)interactive
{
    if (interactive) {
        SRGMedia *media = subdivision ? [self.letterboxController.mediaComposition mediaForSubdivision:subdivision] : self.letterboxController.fullLengthMedia;
        [self reloadDataOverriddenWithMedia:media];
    }
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(nonnull void (^)(BOOL))completionHandler
{
    static const UILayoutPriority LetterboxViewConstraintLowerPriority = 850;
    static const UILayoutPriority LetterboxViewConstraintGreaterPriority = 950;
    
    void (^animations)(void) = ^{
        if (fullScreen) {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintGreaterPriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintLowerPriority;
            self.sizeView.alpha = 0.f;
        }
        else {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintLowerPriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintGreaterPriority;
            self.sizeView.alpha = 1.f;
        }
    };
    
    self.wantsFullScreen = fullScreen;
    
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self.view layoutIfNeeded];
        } completion:completionHandler];
    }
    else {
        animations();
        completionHandler(YES);
    }
}

- (BOOL)letterboxViewShouldDisplayFullScreenToggleButton:(SRGLetterboxView *)letterboxView
{
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

- (BOOL)letterboxView:(SRGLetterboxView *)letterboxView shouldDisplayFavoriteForSubdivision:(SRGSubdivision *)subdivision
{
    return [self.favoritedSubdivisions containsObject:subdivision];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didLongPressSubdivision:(SRGSubdivision *)subdivision
{
    if ([self.favoritedSubdivisions containsObject:subdivision]) {
        [self.favoritedSubdivisions removeObject:subdivision];
    }
    else {
        [self.favoritedSubdivisions addObject:subdivision];
    }
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ! [touch.view isKindOfClass:[UISlider class]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [otherGestureRecognizer isKindOfClass:[SRGActivityGestureRecognizer class]];
}

#pragma mark UIViewControllerTransitioningDelegate protocol

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[ModalTransition alloc] initForPresentation:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[ModalTransition alloc] initForPresentation:NO];
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    // Return the installed interactive transition, if any
    return self.interactiveTransition;
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

- (IBAction)toggleFullScreen:(id)sender
{
    [self.letterboxView setFullScreen:YES animated:YES];
}

- (IBAction)toggleTimeline:(UISwitch *)sender
{
    [self.letterboxView setTimelineAlwaysHidden:! sender.on animated:YES];
}

- (IBAction)pullDown:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGFloat progress = [panGestureRecognizer translationInView:self.view].y / CGRectGetHeight(self.view.frame);
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // Avoid duplicate dismissal (which can make it impossible to dismiss the view controller altogether)
            if (self.interactiveTransition) {
                return;
            }
            
            // Install the interactive transition animation before triggering it
            self.interactiveTransition = [[ModalTransition alloc] initForPresentation:NO];
            [self dismissViewControllerAnimated:YES completion:^{
                // Only stop tracking the interactive transition at the very end. The completion block is called
                // whether the transition ended or was cancelled
                self.interactiveTransition = nil;
            }];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            [self.interactiveTransition updateInteractiveTransitionWithProgress:progress];
            break;
        }
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            [self.interactiveTransition cancelInteractiveTransition];
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            // Finish the transition if the view was dragged by 20% and the user is dragging downwards
            CGFloat velocity = [panGestureRecognizer velocityInView:self.view].y;
            if (progress > 0.2f && velocity >= 0.f) {
                [self.interactiveTransition finishInteractiveTransition];
            }
            else {
                [self.interactiveTransition cancelInteractiveTransition];
            }
            break;
        }
            
        default: {
            break;
        }
    }
}

- (IBAction)changeMargins:(UISlider *)slider
{
    [self.letterboxMarginConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = slider.maximumValue - slider.value;
    }];
}

- (IBAction)changeHeightOffset:(UISlider *)slider
{
    // Force a layout. The updated offset value will be added to the recommended aspect ratio constant in
    // `-letterboxViewWillAnimateUserInterface:` implementation
    [self.letterboxView setNeedsLayout];
}

- (IBAction)toggleView:(id)sender
{
    if (self.letterboxView.controller) {
        self.letterboxView.controller = nil;
    }
    else {
        self.letterboxView.controller = self.letterboxController;
    }
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self reloadDataOverriddenWithMedia:nil];
}

@end
