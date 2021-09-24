//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AdvancedPlayerViewController.h"

#import "ModalTransition.h"
#import "NSBundle+LetterboxDemo.h"
#import "Playlist.h"
#import "SettingsViewController.h"
#import "UIApplication+LetterboxDemo.h"
#import "UILabel+Copyable.h"
#import "UIWindow+LetterboxDemo.h"

@import libextobjc;
@import SRGAnalytics;
@import SRGDataProviderNetwork;

@interface AdvancedPlayerViewController ()

@property (nonatomic, copy) NSString *URN;
@property (nonatomic, copy) SRGMedia *media;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *serverLabel;
@property (nonatomic, weak) IBOutlet UILabel *URNLabel;

@property (nonatomic, weak) IBOutlet UISwitch *timelineSwitch;

@property (nonatomic, weak) IBOutlet UIView *sizeView;
@property (nonatomic, weak) IBOutlet UISlider *heightOffsetSlider;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *letterboxMarginConstraints;

@property (nonatomic) ModalTransition *interactiveTransition;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) Playlist *playlist;

@end

@implementation AdvancedPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(NSString *)URN media:(SRGMedia *)media serviceURL:(NSURL *)serviceURL
{
    SRGLetterboxService *service = SRGLetterboxService.sharedService;
    
    if (media) {
        URN = media.URN;
    }
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if (service.controller.pictureInPictureActive && [service.pictureInPictureDelegate isKindOfClass:self.class] && [service.controller.URN isEqual:URN]) {
        return (AdvancedPlayerViewController *)service.pictureInPictureDelegate;
    }
    // Otherwise instantiate a fresh new one
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LetterboxDemoResourceNameForUIClass(self.class) bundle:nil];
        AdvancedPlayerViewController *viewController = [storyboard instantiateInitialViewController];
        
        viewController.URN = URN;
        viewController.media = media;
        
        viewController.letterboxController.serviceURL = serviceURL ?: ApplicationSettingServiceURL();
        viewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
        viewController.letterboxController.globalParameters = ApplicationSettingGlobalParameters();
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

#pragma mark Getters and setters

- (NSTimeInterval)updateInterval
{
    return self.letterboxController.updateInterval;
}

- (void)setUpdateInterval:(NSTimeInterval)updateInterval
{
    self.letterboxController.updateInterval = updateInterval;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
        
    self.transitioningDelegate = self;   
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.URNLabel.copyingEnabled = YES;
    
    self.closeButton.accessibilityLabel = NSLocalizedString(@"Close", nil);
    
    self.timelineSwitch.enabled = ! self.letterboxView.timelineAlwaysHidden;
    
    [SRGLetterboxService.sharedService enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    // Always display the full-screen interface in landscape orientation
    UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
    BOOL isLandscape = UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation) ? UIDeviceOrientationIsLandscape(deviceOrientation) : UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
    [self.letterboxView setFullScreen:isLandscape animated:NO];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(metadataDidChange:)
                                               name:SRGLetterboxMetadataDidChangeNotification
                                             object:self.letterboxController];
    
    self.letterboxController.contentURLOverridingBlock = ^(NSString * _Nonnull URN) {
        NSURL *overriddenURL = nil;
        if ([URN isEqualToString:@"urn:rts:video:8806790"]) {
            overriddenURL = [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
        }
        else if ([URN isEqualToString:@"urn:rts:audio:8798735"]) {
            overriddenURL = [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8"];
        }
        return overriddenURL;
    };
    
    if (self.URN) {
        SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
        settings.standalone = ApplicationSettingStandalone();
        settings.quality = ApplicationSettingPreferredQuality();
        
        if (self.media) {
            [self.letterboxController playMedia:self.media atPosition:nil withPreferredSettings:settings];
        }
        else {
            [self.letterboxController playURN:self.URN atPosition:nil withPreferredSettings:settings];
        }
    }
    
    if (self.URN) {
        self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.letterboxController.serviceURL];
        
        @weakify(self)
        [[self.dataProvider recommendedMediasForURN:self.URN userId:nil withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            @strongify(self)
            self.playlist = [[Playlist alloc] initWithMedias:medias sourceUid:nil];
            self.playlist.continuousPlaybackTransitionDuration = ApplicationSettingAutoplayEnabled() ? 15. : SRGLetterboxContinuousPlaybackDisabled ;
            self.letterboxController.playlistDataSource = self.playlist;
            self.letterboxController.playbackTransitionDelegate = self.playlist;
        }] resume];
    }
    
    // Start with a hidden interface. Performed after a URN has been assigned so that no UI is visible at all
    // initially (see -letterboxViewWillAnimateUserInterface: implementation)
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
    
    [self reloadData];
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

#pragma mark Keyboard shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands
{
    NSMutableArray<UIKeyCommand *> *keyCommands = [NSMutableArray array];
    
    UIKeyCommand *togglePlayPauseCommand = [UIKeyCommand keyCommandWithInput:@" "
                                                               modifierFlags:0
                                                                      action:@selector(togglePlayPause:)
                                                        discoverabilityTitle:NSLocalizedString(@"Play / Pause", @"Play / Pause keyboard shortcut label")];
    [keyCommands addObject:togglePlayPauseCommand];
    
    if ([self.letterboxController canSkipWithInterval:SRGLetterboxForwardSkipInterval]) {
        UIKeyCommand *skipForwardCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                                               modifierFlags:0
                                                                      action:@selector(skipForward:)
                                                        discoverabilityTitle:NSLocalizedString(@"Skip Ahead", @"Skip ahead shortcut label")];
        if (@available(iOS 15, *)) {
            skipForwardCommand.wantsPriorityOverSystemBehavior = YES;
        }
        [keyCommands addObject:skipForwardCommand];
    }
    
    if ([self.letterboxController canSkipWithInterval:-SRGLetterboxBackwardSkipInterval]) {
        UIKeyCommand *skipBackwardCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                                                modifierFlags:0
                                                                       action:@selector(skipBackward:)
                                                         discoverabilityTitle:NSLocalizedString(@"Skip Back", @"Skip back shortcut label")];
        if (@available(iOS 15, *)) {
            skipBackwardCommand.wantsPriorityOverSystemBehavior = YES;
        }
        [keyCommands addObject:skipBackwardCommand];
    }
    
    return keyCommands.copy;
}

- (void)togglePlayPause:(UIKeyCommand *)command
{
    [self.letterboxController togglePlayPause];
}

- (void)skipForward:(UIKeyCommand *)command
{
    [self.letterboxController skipWithInterval:SRGLetterboxForwardSkipInterval completionHandler:nil];
}

- (void)skipBackward:(UIKeyCommand *)command
{
    [self.letterboxController skipWithInterval:-SRGLetterboxBackwardSkipInterval completionHandler:nil];
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
    
    self.serverLabel.text = media.URN ? [NSString stringWithFormat:@"%@ urn:", LetterboxDemoServiceNameForURL(self.letterboxController.serviceURL)] : nil;
    self.URNLabel.text = media.URN;
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

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, BOOL minimal, CGFloat aspectRatio, CGFloat heightOffset) {
        self.letterboxAspectRatioConstraint = [self.letterboxAspectRatioConstraint srg_replacementConstraintWithMultiplier:fminf(1.f / aspectRatio, 1.f)
                                                                                                                  constant:heightOffset + self.heightOffsetSlider.value];
        self.closeButton.alpha = (minimal || ! hidden) ? 1.f : 0.f;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didScrollWithSubdivision:(SRGSubdivision *)subdivision time:(CMTime)time date:(NSDate *)date interactive:(BOOL)interactive
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
    return UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation);
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ! [touch.view isKindOfClass:UISlider.class];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [otherGestureRecognizer.view isKindOfClass:UIScrollView.class];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [otherGestureRecognizer isKindOfClass:SRGActivityGestureRecognizer.class];
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

- (IBAction)stop:(id)sender
{
    [self.letterboxController stop];
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
            if ((progress <= 0.5f && velocity > 1000.f) || (progress > 0.5f && velocity > -1000.f)) {
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
        constraint.constant = (slider.maximumValue - slider.value) * 100;
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
