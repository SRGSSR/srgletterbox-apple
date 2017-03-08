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

@property (nonatomic, weak) IBOutlet UIPickerView *preferredTimelineHeight;

// Switching to and from full-screen is made by adjusting the priority / constance of a constraint of the letterbox
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic, getter=isTransitioningToFullScreen) BOOL wantsFullScreen;

@property (nonatomic) NSMutableArray<SRGSegment *> *favoriteSegments;

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
        viewController.favoriteSegments = @[].mutableCopy;
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
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    // Start with a hidden interface
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
    
    // Always display the full-screen interface in landscape orientation
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    BOOL isLandscape = UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation) ? UIDeviceOrientationIsLandscape(deviceOrientation) : UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    [self.letterboxView setFullScreen:isLandscape animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        // Special case to test multi chapters and segments. Should be removed when an example is available in production
        if ([self.URN.uid containsString:@","]) {
            self.letterboxController.serviceURL = [NSURL URLWithString:@"https://play-mmf.herokuapp.com"];
        }
        else {
            self.letterboxController.serviceURL = nil;
        }
        
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

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        BOOL isLandscape = (size.width > size.height);
        [self.letterboxView setFullScreen:isLandscape animated:NO];
    } completion:nil];
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
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, CGFloat expansionHeight) {
        self.letterboxAspectRatioConstraint.constant = expansionHeight;
        self.closeButton.alpha = (hidden && ! self.letterboxController.error && self.URN) ? 0.f : 1.f;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(nonnull void (^)(BOOL))completionHandler
{
    void (^animations)(void) = ^{
        if (fullScreen) {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintMorePriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintLessPriority;
        }
        else {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintLessPriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintMorePriority;
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

- (BOOL)letterboxView:(SRGLetterboxView *)letterboxView hideFavoriteOnSegment:(SRGSegment *)segment
{
    return ! [self.favoriteSegments containsObject:segment];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didLongPressOnSegment:(SRGSegment *)segment
{
    if ([self.favoriteSegments containsObject:segment]) {
        [self.favoriteSegments removeObject:segment];
    }
    else {
        [self.favoriteSegments addObject:segment];
    }
}

#pragma mark UIPickerViewDataSource protocol

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}

#pragma mark UIPickerViewDelegate protocol

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = nil;
    switch (row) {
        case 0:
            title = @(120).stringValue;
            break;
        case 1:
            title = @(80).stringValue;
            break;
        case 2:
            title = @(0).stringValue;
            break;
            
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"Timeline height %@", title];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    CGFloat preferredTimelineHeight = 120.f;
    switch (row) {
        case 0:
            preferredTimelineHeight = 120.f;
            break;
        case 1:
            preferredTimelineHeight = 80.f;
            break;
        case 2:
            preferredTimelineHeight = 0.f;
            break;
            
        default:
            break;
    }
    
    [self.letterboxView setPreferredTimelineHeight:preferredTimelineHeight animated:YES];
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
