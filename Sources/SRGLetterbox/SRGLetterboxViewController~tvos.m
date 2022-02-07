//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_TV

#import "SRGLetterboxViewController.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGAvailabilityView.h"
#import "SRGContinuousPlaybackViewController.h"
#import "SRGErrorView.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxMetadata.h"
#import "SRGLiveLabel.h"
#import "SRGNotificationView.h"
#import "UIApplication+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"
#import "UIWindow+SRGLetterbox.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGAppearance;
@import SRGMediaPlayer;
@import YYWebImage;

static UIView *SRGLetterboxViewControllerPlayerSubview(UIView *view)
{
    if ([view.layer isKindOfClass:AVPlayerLayer.class]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *playerSubview = SRGLetterboxViewControllerPlayerSubview(subview);
        if (playerSubview) {
            return playerSubview;
        }
    }
    
    return nil;
}

static UIView *SRGLetterboxViewControllerLoadingIndicatorSubview(UIView *view)
{
    if ([NSStringFromClass(view.class) containsString:@"LoadingIndicator"]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *loadingView = SRGLetterboxViewControllerLoadingIndicatorSubview(subview);
        if (loadingView) {
            return loadingView;
        }
    }
    
    return nil;
}

static NSMutableSet<SRGLetterboxViewController *> *s_letterboxViewControllers;

@interface SRGLetterboxViewController () <SRGContinuousPlaybackViewControllerDelegate, SRGMediaPlayerViewControllerDelegate>

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) SRGMediaPlayerViewController *playerViewController;

@property (nonatomic) NSMutableDictionary<NSURL *, YYWebImageOperation *> *imageOperations;

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) SRGAvailabilityView *availabilityView;
@property (nonatomic, weak) SRGErrorView *errorView;
@property (nonatomic, weak) UIImageView *loadingImageView;
@property (nonatomic, weak) SRGNotificationView *notificationView;

@property (nonatomic, weak) NSLayoutConstraint *notificationViewWidthConstraint;
@property (nonatomic, weak) NSLayoutConstraint *notificationViewHeightConstraint;

@property (nonatomic, weak) SRGLiveLabel *liveLabel;

@property (nonatomic) NSArray<UIAction *> *defaultInfoViewActions API_AVAILABLE(tvos(15.0));
@property (nonatomic, weak) id periodicTimeObserver API_AVAILABLE(tvos(15.0));

@property (nonatomic, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;
@property (nonatomic, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

@end

@implementation SRGLetterboxViewController

#pragma mark Class methods

+ (void)addLetterboxViewController:(SRGLetterboxViewController *)letterboxViewController
{
    if (! s_letterboxViewControllers) {
        s_letterboxViewControllers = [NSMutableSet set];
    }
    [s_letterboxViewControllers addObject:letterboxViewController];
}

+ (void)removeLetterboxViewController:(SRGLetterboxViewController *)letterboxViewController
{
    [s_letterboxViewControllers removeObject:letterboxViewController];
}

#pragma mark Object lifecycle

- (instancetype)initWithController:(SRGLetterboxController *)controller
{
    if (self = [super init]) {
        if (! controller) {
            controller = [[SRGLetterboxController alloc] init];
        }
        
        self.controller = controller;
        self.playerViewController = [[SRGMediaPlayerViewController alloc] initWithController:controller.mediaPlayerController];
        self.playerViewController.delegate = self;
        self.userInterfaceHidden = YES;
        
        self.imageOperations = [NSMutableDictionary dictionary];
        
        @weakify(self) @weakify(controller)
        [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
            @strongify(self) @strongify(controller)
            
            SRGMedia *upcomingMedia = controller.continuousPlaybackUpcomingMedia;
            if (upcomingMedia) {
                SRGContinuousPlaybackViewController *continuousPlaybackViewController = [[SRGContinuousPlaybackViewController alloc] initWithMedia:controller.media
                                                                                                                                     upcomingMedia:upcomingMedia
                                                                                                                                           endDate:controller.continuousPlaybackTransitionEndDate];
                continuousPlaybackViewController.delegate = self;
                [self presentViewController:continuousPlaybackViewController animated:YES completion:nil];
            }
        }];
        [controller addObserver:self keyPath:@keypath(controller.loading) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateMainLayoutAnimated:YES];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(metadataDidChange:)
                                                   name:SRGLetterboxMetadataDidChangeNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGLetterboxPlaybackStateDidChangeNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackDidFail:)
                                                   name:SRGLetterboxPlaybackDidFailNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(livestreamDidFinish:)
                                                   name:SRGLetterboxLivestreamDidFinishNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackDidContinueAutomatically:)
                                                   name:SRGLetterboxPlaybackDidContinueAutomaticallyNotification
                                                 object:controller];
        
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.mediaType) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateMainLayoutAnimated:YES];
        }];
        [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.live) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateMainLayoutAnimated:YES];
        }];
        
        if (@available(tvOS 15, *)) {
            self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
                @strongify(self)
                [self updateInfoViewActions];
            }];
            [self updateInfoViewActions];
            
            [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.playbackRate) options:0 block:^(MAKVONotification *notification) {
                @strongify(self)
                [self updateTransportBarMenu];
            }];
            [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.alternativePlaybackRates) options:0 block:^(MAKVONotification *notification) {
                @strongify(self)
                [self updateTransportBarMenu];
            }];
            [self updateTransportBarMenu];
        }
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willSkipBlockedSegment:)
                                                   name:SRGMediaPlayerWillSkipBlockedSegmentNotification
                                                 object:mediaPlayerController];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithController:nil];
}

- (void)dealloc
{
    [self.imageOperations enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull URL, YYWebImageOperation * _Nonnull operation, BOOL * _Nonnull stop) {
        [operation cancel];
    }];
    if (@available(tvOS 15, *)) {
        [self.controller removePeriodicTimeObserver:self.periodicTimeObserver];
    }
    [self.playerViewController removeFromParentViewController];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    
    // In -viewDidLoad so that we can inject our hierarchy into the standard player layout
    [self layoutPlayerViewInView:self.view];
    [self layoutNotificationViewInView:self.view];
    [self loadLoadingImageViewInView:self.view];
    [self loadErrorViewInView:self.view];
    [self loadAvailabilityViewInView:self.view];
    [self loadLiveLabel];
        
    [self updateMainLayoutAnimated:NO];
    [self reloadImage];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        [self dismissNotificationViewAnimated:NO];
        
        if (! self.pictureInPictureActive) {
            [self.controller reset];
        }
    }
}

#pragma mark Layout helpers

- (void)layoutPlayerViewInView:(UIView *)view
{
    UIView *playerView = self.playerViewController.view;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    playerView.backgroundColor = UIColor.clearColor;
    [view addSubview:playerView];
    [self addChildViewController:self.playerViewController];
    
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:playerView.bounds];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [view insertSubview:imageView belowSubview:playerView];
    self.imageView = imageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
}

- (void)layoutNotificationViewInView:(UIView *)view
{
    SRGNotificationView *notificationView = [[SRGNotificationView alloc] init];
    notificationView.translatesAutoresizingMaskIntoConstraints = NO;
    notificationView.alpha = 0.f;
    notificationView.layer.cornerRadius = 3.f;
    notificationView.layer.shadowOpacity = 0.5f;
    notificationView.layer.shadowOffset = CGSizeMake(0.f, 2.f);
    [view insertSubview:notificationView aboveSubview:self.playerViewController.view];
    self.notificationView = notificationView;
    
    [NSLayoutConstraint activateConstraints:@[
        [notificationView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [notificationView.topAnchor constraintEqualToAnchor:view.topAnchor constant:20.f],
        self.notificationViewWidthConstraint = [notificationView.widthAnchor constraintEqualToConstant:0.f],
        self.notificationViewHeightConstraint = [notificationView.heightAnchor constraintEqualToConstant:0.f],
    ]];
}

- (void)loadLoadingImageViewInView:(UIView *)view
{
    // Hide the standard system UI
    UIView *playerView = self.playerViewController.view;
    UIView *loadingIndicatorView = SRGLetterboxViewControllerLoadingIndicatorSubview(playerView);
    loadingIndicatorView.alpha = 0.f;
    
    UIImageView *loadingImageView = [UIImageView srg_loadingImageViewWithTintColor:UIColor.whiteColor];
    loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
    loadingImageView.alpha = 0.f;
    loadingImageView.userInteractionEnabled = NO;
    [loadingImageView startAnimating];
    [view insertSubview:loadingImageView aboveSubview:playerView];
    self.loadingImageView = loadingImageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [loadingImageView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [loadingImageView.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
}

- (void)loadErrorViewInView:(UIView *)view
{
    SRGErrorView *errorView = [[SRGErrorView alloc] init];
    errorView.translatesAutoresizingMaskIntoConstraints = NO;
    errorView.controller = self.controller;
    errorView.userInteractionEnabled = NO;
    [view insertSubview:errorView aboveSubview:self.playerViewController.view];
    self.errorView = errorView;
    
    [NSLayoutConstraint activateConstraints:@[
        [errorView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [errorView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [errorView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [errorView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
}

- (void)loadAvailabilityViewInView:(UIView *)view
{
    SRGAvailabilityView *availabilityView = [[SRGAvailabilityView alloc] init];
    availabilityView.translatesAutoresizingMaskIntoConstraints = NO;
    availabilityView.controller = self.controller;
    availabilityView.userInteractionEnabled = NO;
    [view insertSubview:availabilityView aboveSubview:self.playerViewController.view];
    self.availabilityView = availabilityView;
    
    [NSLayoutConstraint activateConstraints:@[
        [availabilityView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [availabilityView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [availabilityView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [availabilityView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
}

- (void)loadLiveLabel
{
    UIView *contentOverlayView = self.playerViewController.contentOverlayView;
    SRGLiveLabel *liveLabel = [[SRGLiveLabel alloc] init];
    liveLabel.translatesAutoresizingMaskIntoConstraints = NO;
    liveLabel.layer.shadowRadius = 5.f;
    liveLabel.layer.shadowOpacity = 0.5f;
    liveLabel.layer.shadowOffset = CGSizeMake(0.f, 2.f);
    [contentOverlayView addSubview:liveLabel];
    self.liveLabel = liveLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [liveLabel.trailingAnchor constraintEqualToAnchor:contentOverlayView.trailingAnchor constant:-100.f],
        [liveLabel.topAnchor constraintEqualToAnchor:contentOverlayView.topAnchor constant:50.f],
        [liveLabel.heightAnchor constraintEqualToConstant:45.f]
    ]];
}

#pragma mark Image retrieval

- (UIImage *)imageForMetadata:(id<SRGImageMetadata>)metadata withCompletion:(void (^)(void))completion
{
    NSParameterAssert(completion);
    
    YYWebImageManager *webImageManager = [YYWebImageManager sharedManager];
    
    CGFloat width = SRGWidthForImageScale(SRGImageScaleMedium);
    NSURL *imageURL = [metadata imageURLForDimension:SRGImageDimensionWidth withValue:width type:SRGImageTypeDefault];
    NSString *key = [webImageManager cacheKeyForURL:imageURL];
    UIImage *image = [webImageManager.cache getImageForKey:key];
    if (image) {
        return image;
    }
    
    if (imageURL && ! self.imageOperations[imageURL]) {
        @weakify(self)
        YYWebImageOperation *imageOperation = [webImageManager requestImageWithURL:imageURL options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
            @strongify(self)
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageOperations[imageURL] = nil;
                completion();
            });
        }];
        self.imageOperations[imageURL] = imageOperation;
    }
    
    return [UIImage srg_vectorImageAtPath:SRGLetterboxFilePathForImagePlaceholder() withWidth:width];
}

#pragma mark Data

- (void)reloadImage
{
    [self.imageView srg_requestImageForObject:self.controller.displayableMedia withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
}

- (void)reloadPlaceholderImage
{
    [self.imageView srg_requestImageForObject:nil withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
}

#pragma mark Layout

- (void)updateMainLayoutAnimated:(BOOL)animated
{
    [self updateMainLayoutWithUserInterfaceHidden:self.userInterfaceHidden animated:animated];
}

- (void)updateMainLayoutWithUserInterfaceHidden:(BOOL)userInterfaceHidden animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
        BOOL isPlaying = playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStatePreparing && playbackState != SRGMediaPlayerPlaybackStateEnded;
        
        BOOL playerViewVisible = (self.controller.media.mediaType == SRGMediaTypeVideo && isPlaying);
        UIView *playerView = SRGLetterboxViewControllerPlayerSubview(self.view);
        playerView.alpha = playerViewVisible ? 1.f : 0.f;
        self.imageView.alpha = playerViewVisible ? 0.f : 1.f;
        
        NSError *error = self.controller.error;
        if ([error.domain isEqualToString:SRGLetterboxErrorDomain] && error.code == SRGLetterboxErrorCodeNotAvailable) {
            self.errorView.alpha = 0.f;
            self.availabilityView.alpha = 1.f;
        }
        else if (error) {
            self.errorView.alpha = 1.f;
            self.availabilityView.alpha = 0.f;
        }
        else if (self.controller.URN) {
            self.errorView.alpha = 0.f;
            self.availabilityView.alpha = 0.f;
        }
        else {
            self.errorView.alpha = 1.f;
            self.availabilityView.alpha = 0.f;
        }
        
        if (self.controller.loading) {
            self.loadingImageView.alpha = 1.f;
        }
        else {
            self.loadingImageView.alpha = 0.f;
        }
        
        self.liveLabel.alpha = (! userInterfaceHidden && self.controller.live) ? 1.f : 0.f;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.4 animations:animations];
    }
    else {
        animations();
    }
}

#pragma mark Actions

- (void)updateInfoViewActions API_AVAILABLE(tvos(15.0))
{
    if (! self.defaultInfoViewActions) {
        self.defaultInfoViewActions = self.playerViewController.infoViewActions;
    }
    
    switch (self.controller.mediaPlayerController.streamType) {
        case SRGStreamTypeOnDemand: {
            self.playerViewController.infoViewActions = self.defaultInfoViewActions;
            break;
        }
            
        case SRGStreamTypeDVR: {
            NSMutableArray<UIAction *> *infoViewActions = [NSMutableArray array];
            if ([self.controller canStartOver]) {
                UIAction *action = [UIAction actionWithTitle:SRGLetterboxLocalizedString(@"Start over", @"Start over button label")
                                                       image:[UIImage srg_letterboxStartOverImageInSet:SRGImageSetNormal]
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    [self.controller startOverWithCompletionHandler:nil];
                }];
                [infoViewActions addObject:action];
            }
            if ([self.controller canSkipToLive]) {
                UIAction *action = [UIAction actionWithTitle:SRGLetterboxLocalizedString(@"Back to live", @"Back to live button label")
                                                       image:[UIImage srg_letterboxSkipToLiveImageInSet:SRGImageSetNormal]
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    [self.controller skipToLiveWithCompletionHandler:nil];
                }];
                [infoViewActions addObject:action];
            }
            self.playerViewController.infoViewActions = infoViewActions.copy;
            break;
        }
            
        default: {
            self.playerViewController.infoViewActions = @[];
            break;
        }
    }
}

- (NSArray<UIAction *> *)playbackRateMenuActions API_AVAILABLE(tvos(15.0))
{
    NSMutableArray<UIAction *> *actions = [NSMutableArray array];
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    for (NSNumber *rate in mediaPlayerController.supportedPlaybackRates) {
        @weakify(mediaPlayerController)
        UIAction *action = [UIAction actionWithTitle:[NSString stringWithFormat:@"%@×", rate] image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            @strongify(mediaPlayerController)
            mediaPlayerController.playbackRate = rate.floatValue;
            action.state = UIMenuElementStateOn;
        }];
        action.state = [rate isEqualToNumber:@(mediaPlayerController.playbackRate)] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    return actions.copy;
}

- (void)updateTransportBarMenu API_AVAILABLE(tvos(15.0))
{
    UIMenu *playbackRateMenu = [UIMenu menuWithTitle:SRGLetterboxLocalizedString(@"Playback speed", @"Playback speed menu title")
                                               image:[UIImage systemImageNamed:@"speedometer"]
                                          identifier:nil
                                             options:UIMenuOptionsSingleSelection
                                            children:[self playbackRateMenuActions]];
    self.playerViewController.transportBarCustomMenuItems = @[playbackRateMenu];
}

#pragma mark Notification banners

- (void)showNotificationMessage:(NSString *)notificationMessage animated:(BOOL)animated
{
    if (notificationMessage.length == 0) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissNotificationViewAutomatically) object:nil];
    
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, notificationMessage);
    CGSize notificationSize = [self.notificationView updateLayoutWithMessage:notificationMessage width:CGRectGetWidth(self.view.frame) - 100.f];
    self.notificationViewWidthConstraint.constant = notificationSize.width;
    self.notificationViewHeightConstraint.constant = notificationSize.height;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.notificationView.alpha = 1.f;
    }];
    
    [self performSelector:@selector(dismissNotificationViewAutomatically) withObject:nil afterDelay:5.];
}

- (void)dismissNotificationViewAutomatically
{
    [self dismissNotificationViewAnimated:YES];
}

- (void)dismissNotificationViewAnimated:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissNotificationViewAutomatically) object:nil];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.notificationView.alpha = 0.f;
    } completion:^(BOOL finished) {
        CGSize notificationSize = [self.notificationView updateLayoutWithMessage:nil width:CGRectGetWidth(self.view.frame) - 100.f];
        self.notificationViewWidthConstraint.constant = notificationSize.width;
        self.notificationViewHeightConstraint.constant = notificationSize.height;
    }];
}

#pragma mark AVPlayerViewControllerDelegate protocol

- (BOOL)playerViewControllerShouldDismiss:(AVPlayerViewController *)playerViewController
{
    [playerViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController willTransitionToVisibilityOfTransportBar:(BOOL)visible withAnimationCoordinator:(id<AVPlayerViewControllerAnimationCoordinator>)coordinator API_AVAILABLE(tvos(11.0))
{
    self.userInterfaceHidden = ! visible;
    
    [coordinator addCoordinatedAnimations:^{
        [self updateMainLayoutWithUserInterfaceHidden:! visible animated:NO];
    } completion:nil];
}

- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController
{
    if (@available(tvOS 14, *)) {
        [SRGLetterboxViewController addLetterboxViewController:self];
        
        self.pictureInPictureActive = YES;
        
        if ([self.delegate respondsToSelector:@selector(letterboxViewControllerWillStartPictureInPicture:)]) {
            [self.delegate letterboxViewControllerWillStartPictureInPicture:self];
        }
    }
}

- (void)playerViewControllerDidStartPictureInPicture:(AVPlayerViewController *)playerViewController
{
    if (@available(tvOS 14, *)) {
        if ([self.delegate respondsToSelector:@selector(letterboxViewControllerDidStartPictureInPicture:)]) {
            [self.delegate letterboxViewControllerDidStartPictureInPicture:self];
        }
    }
}

- (void)playerViewControllerWillStopPictureInPicture:(AVPlayerViewController *)playerViewController
{
    if (@available(tvOS 14, *)) {
        if ([self.delegate respondsToSelector:@selector(letterboxViewControllerWillStopPictureInPicture:)]) {
            [self.delegate letterboxViewControllerWillStopPictureInPicture:self];
        }
    }
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController
{
    if (@available(tvOS 14, *)) {
        self.pictureInPictureActive = NO;
        
        if ([self.delegate respondsToSelector:@selector(letterboxViewControllerDidStopPictureInPicture:)]) {
            [self.delegate letterboxViewControllerDidStopPictureInPicture:self];
        }
        
        [SRGLetterboxViewController removeLetterboxViewController:self];
    }
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (@available(tvOS 14, *)) {
        void (^presentPlayer)(void) = ^{
            // Do not animate on tvOS to avoid UI glitches when swapping
            UIViewController *topViewController = UIApplication.sharedApplication.srg_letterboxMainWindow.srg_letterboxTopViewController;
            [topViewController presentViewController:self animated:NO completion:^{
                completionHandler(YES);
            }];
        };
        
        // On tvOS dismiss any existing player first, otherwise picture in picture will be stopped when swapping
        UIViewController *topViewController = UIApplication.sharedApplication.srg_letterboxMainWindow.srg_letterboxTopViewController;
        if ([topViewController isKindOfClass:SRGLetterboxViewController.class] || [topViewController isKindOfClass:AVPlayerViewController.class]) {
            [topViewController dismissViewControllerAnimated:NO completion:presentPlayer];
        }
        else {
            presentPlayer();
        }
    }
}

#pragma mark SRGContinuousPlaybackViewControllerDelegate protocol

- (void)continuousPlaybackViewController:(SRGContinuousPlaybackViewController *)continuousPlaybackViewController didEngageInContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self reloadPlaceholderImage];
    [self.controller playUpcomingMedia];
    
    if ([self.delegate respondsToSelector:@selector(letterboxViewController:didEngageInContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxViewController:self didEngageInContinuousPlaybackWithUpcomingMedia:upcomingMedia];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)continuousPlaybackViewController:(SRGContinuousPlaybackViewController *)continuousPlaybackViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self.controller cancelContinuousPlayback];
    
    if ([self.delegate respondsToSelector:@selector(letterboxViewController:didCancelContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxViewController:self didCancelContinuousPlaybackWithUpcomingMedia:upcomingMedia];
    }
    
    [self dismissViewControllerAnimated:NO completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)continuousPlaybackViewController:(SRGContinuousPlaybackViewController *)continuousPlaybackViewController didRestartPlaybackWithMedia:(SRGMedia *)media cancelledUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self.controller restart];
    
    if ([self.delegate respondsToSelector:@selector(letterboxViewController:didCancelContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxViewController:self didCancelContinuousPlaybackWithUpcomingMedia:upcomingMedia];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SRGMediaPlayerViewControllerDelegate protocol

- (NSArray<AVMetadataItem *> *)playerViewControllerExternalMetadata:(SRGMediaPlayerViewController *)playerViewController
{
    SRGMedia *media = self.controller.fullLengthMedia;
    if (media) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
        titleItem.identifier = AVMetadataCommonIdentifierTitle;
        titleItem.value = SRGLetterboxMetadataTitle(media);
        titleItem.extendedLanguageTag = @"und";
        
        AVMutableMetadataItem *subtitleItem = [[AVMutableMetadataItem alloc] init];
        subtitleItem.identifier = AVMetadataIdentifieriTunesMetadataTrackSubTitle;
        subtitleItem.value = SRGLetterboxMetadataSubtitle(media);
        subtitleItem.extendedLanguageTag = @"und";
        
        AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
        descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
        descriptionItem.value = SRGLetterboxMetadataDescription(media);
        descriptionItem.extendedLanguageTag = @"und";
        
        UIImage *image = [self imageForMetadata:media withCompletion:^{
            [playerViewController reloadData];
        }];
        
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        artworkItem.value = UIImagePNGRepresentation(image);
        artworkItem.extendedLanguageTag = @"und";       // Also required for images in external metadata
        
        return @[ titleItem.copy, subtitleItem.copy, descriptionItem.copy, artworkItem.copy ];
    }
    else {
        return nil;
    }
}

- (NSArray<AVTimedMetadataGroup *> *)playerViewController:(SRGMediaPlayerViewController *)playerViewController navigationMarkersForSegments:(NSArray<id<SRGSegment>> *)segments
{
    NSMutableArray<AVTimedMetadataGroup *> *navigationMarkers = [NSMutableArray array];
    
    for (SRGSegment *segment in segments) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
        titleItem.identifier = AVMetadataCommonIdentifierTitle;
        titleItem.value = segment.title;
        titleItem.extendedLanguageTag = @"und";
        
        UIImage *image = [self imageForMetadata:segment withCompletion:^{
            [playerViewController reloadData];
        }];
        
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        artworkItem.value = UIImagePNGRepresentation(image);
        artworkItem.extendedLanguageTag = @"und";       // Apparently not required, but added for safety / consistency
        
        CMTimeRange segmentTimeRange = [segment.srg_markRange timeRangeForMediaPlayerController:playerViewController.controller];
        AVTimedMetadataGroup *navigationMarker = [[AVTimedMetadataGroup alloc] initWithItems:@[ titleItem.copy, artworkItem.copy ] timeRange:segmentTimeRange];
        [navigationMarkers addObject:navigationMarker];
    }
    
    return navigationMarkers.copy;
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self.playerViewController reloadData];
    [self reloadImage];
    [self updateMainLayoutAnimated:YES];
}

- (void)playbackStateDidChange:(NSNotification *)notification
{   
    [self updateMainLayoutAnimated:YES];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self updateMainLayoutAnimated:YES];
}

- (void)livestreamDidFinish:(NSNotification *)notification
{
    [self showNotificationMessage:SRGLetterboxLocalizedString(@"Live broadcast ended", @"Notification message displayed when a live broadcast has finished.") animated:YES];
}

- (void)playbackDidContinueAutomatically:(NSNotification *)notification
{
    [self reloadPlaceholderImage];
    
    // Only dismiss continuous playback overlay when presented (i.e. when the transition duration is not 0)
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)willSkipBlockedSegment:(NSNotification *)notification
{
    SRGSubdivision *subdivision = notification.userInfo[SRGMediaPlayerSegmentKey];
    NSString *notificationMessage = SRGMessageForSkippedSegmentWithBlockingReason([subdivision blockingReasonAtDate:NSDate.date]);
    [self showNotificationMessage:notificationMessage animated:YES];
}

@end

#endif
