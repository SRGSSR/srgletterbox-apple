//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGControlsView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSLayoutConstraint+SRGLetterboxPrivate.h"
#import "SRGControlButton.h"
#import "SRGControlWrapperView.h"
#import "SRGFullScreenButton.h"
#import "SRGLabeledControlButton.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxService.h"
#import "SRGLetterboxTimeSlider.h"
#import "SRGLetterboxView+Private.h"
#import "SRGLiveLabel.h"
#import "UIImage+SRGLetterbox.h"
#import "UIView+SRGLetterbox.h"

static const CGFloat kNormalIconDimension = 48.f;
static const CGFloat kLargeIconDimension = 64.f;

static const CGFloat kDistanceToCenterNormalUnit = 64.f;
static const CGFloat kDistanceToCenterLargeUnit = 100.f;

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGAppearance;

static NSDateComponentsFormatter *SRGControlsViewSkipIntervalAccessibilityFormatter(void)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond;
    });
    return s_dateComponentsFormatter;
}

@interface SRGControlsView ()

@property (nonatomic, weak) UIView *userInterfaceToggleActiveView;

@property (nonatomic, weak) SRGLetterboxPlaybackButton *playbackButton;
@property (nonatomic, weak) SRGLabeledControlButton *backwardSkipButton;
@property (nonatomic, weak) SRGLabeledControlButton *forwardSkipButton;
@property (nonatomic, weak) SRGControlButton *startOverButton;
@property (nonatomic, weak) SRGLabeledControlButton *skipToLiveButton;

@property (nonatomic, weak) UIStackView *bottomStackView;
@property (nonatomic, weak) SRGViewModeButton *viewModeButton;
@property (nonatomic, weak) SRGAirPlayButton *airPlayButton;
@property (nonatomic, weak) SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) SRGLetterboxTimeSlider *timeSlider;
@property (nonatomic, weak) SRGPlaybackSettingsButton *playbackSettingsButton;
@property (nonatomic, weak) SRGFullScreenButton *fullScreenPhantomButton;

@property (nonatomic, weak) UILabel *durationLabel;
@property (nonatomic, weak) SRGControlWrapperView *durationLabelWrapperView;
@property (nonatomic, weak) SRGLiveLabel *liveLabel;
@property (nonatomic, weak) SRGControlWrapperView *liveLabelWrapperView;

@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingStartOverToPlaybackConstraint;
@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingSkipBackwardToPlaybackConstraint;
@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingPlaybackToSkipForwardConstraint;
@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingPlaybackToSkipToLiveConstraint;

@property (nonatomic, weak) SRGFullScreenButton *fullScreenButton;

@property (nonatomic, getter=isMovingSlider) BOOL movingSlider;

@end

@implementation SRGControlsView

@synthesize userInterfaceStyle = _userInterfaceStyle;

#pragma mark Layout

- (void)layoutContentView
{
    [super layoutContentView];
    
    [self layoutUserInterfaceToggleActiveViewInView:self.contentView];
    [self layoutBottomControlsInView:self.contentView];
    [self layoutCenterControlsInView:self.contentView];
    
    // Track controller changes to ensure picture in picture availability is correctly displayed.
    @weakify(self)
    [SRGLetterboxService.sharedService addObserver:self keyPath:@keypath(SRGLetterboxService.new, controller) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self setNeedsLayoutAnimated:YES];
    }];
}

- (void)layoutUserInterfaceToggleActiveViewInView:(UIView *)view
{
    UIView *userInterfaceToggleActiveView = [[UIView alloc] init];
    [view addSubview:userInterfaceToggleActiveView];
    self.userInterfaceToggleActiveView = userInterfaceToggleActiveView;
    
    userInterfaceToggleActiveView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [userInterfaceToggleActiveView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [userInterfaceToggleActiveView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [userInterfaceToggleActiveView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
    ]];
}

- (void)layoutBottomControlsInView:(UIView *)view
{
    UIStackView *bottomStackView = [[UIStackView alloc] init];
    [view addSubview:bottomStackView];
    self.bottomStackView = bottomStackView;
    
    bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [bottomStackView.topAnchor constraintEqualToAnchor:self.userInterfaceToggleActiveView.bottomAnchor],
        [[bottomStackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor] srgletterbox_withPriority:750],
        [bottomStackView.bottomAnchor constraintLessThanOrEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor],
        [bottomStackView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
        [bottomStackView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor],
        [bottomStackView.heightAnchor constraintEqualToConstant:48.f]
    ]];
    
    [self layoutViewModeButtonInStackView:bottomStackView];
    [self layoutAirPlayButtonInStackView:bottomStackView];
    [self layoutPictureInPictureButtonInStackView:bottomStackView];
    [self layoutTimeSliderInStackView:bottomStackView];
    [self layoutDurationLabelInStackView:bottomStackView];
    [self layoutLiveLabelInStackView:bottomStackView];
    [self layoutPlaybackSettingsButtonInStackView:bottomStackView];
    [self layoutFullScreenPhantomButtonInStackView:bottomStackView];
}

- (void)layoutViewModeButtonInStackView:(UIStackView *)stackView
{
    SRGViewModeButton *viewModeButton = [[SRGViewModeButton alloc] init];
    viewModeButton.tintColor = UIColor.whiteColor;
    viewModeButton.viewModeMonoscopicImage = [UIImage srg_letterboxImageNamed:@"view_mode_monoscopic"];
    viewModeButton.viewModeStereoscopicImage = [UIImage srg_letterboxImageNamed:@"view_mode_stereoscopic"];
    [stackView addArrangedSubview:viewModeButton];
    self.viewModeButton = viewModeButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [[viewModeButton.widthAnchor constraintEqualToConstant:48.f] srgletterbox_withPriority:999]
    ]];
}

- (void)layoutAirPlayButtonInStackView:(UIStackView *)stackView
{
    SRGAirPlayButton *airPlayButton = [[SRGAirPlayButton alloc] init];
    airPlayButton.tintColor = UIColor.whiteColor;
    airPlayButton.audioImage = [UIImage srg_letterboxImageNamed:@"airplay_audio"];
    airPlayButton.videoImage = [UIImage srg_letterboxImageNamed:@"airplay_video"];
    [stackView addArrangedSubview:airPlayButton];
    self.airPlayButton = airPlayButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [[airPlayButton.widthAnchor constraintEqualToConstant:48.f] srgletterbox_withPriority:999]
    ]];
}

- (void)layoutPictureInPictureButtonInStackView:(UIStackView *)stackView
{
    SRGPictureInPictureButton *pictureInPictureButton = [[SRGPictureInPictureButton alloc] init];
    pictureInPictureButton.tintColor = UIColor.whiteColor;
    pictureInPictureButton.startImage = [UIImage srg_letterboxImageNamed:@"picture_in_picture_start"];
    pictureInPictureButton.stopImage = [UIImage srg_letterboxImageNamed:@"picture_in_picture_stop"];
    [stackView addArrangedSubview:pictureInPictureButton];
    self.pictureInPictureButton = pictureInPictureButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [[pictureInPictureButton.widthAnchor constraintEqualToConstant:48.f] srgletterbox_withPriority:999]
    ]];
}

- (void)layoutTimeSliderInStackView:(UIStackView *)stackView
{
    SRGControlWrapperView *timeSliderWrapperView = [[SRGControlWrapperView alloc] init];
    [stackView addArrangedSubview:timeSliderWrapperView];
    
    SRGLetterboxTimeSlider *timeSlider = [[SRGLetterboxTimeSlider alloc] init];
    timeSlider.alpha = 0.f;
    timeSlider.delegate = self;
    [timeSliderWrapperView addSubview:timeSlider];
    self.timeSlider = timeSlider;
    
    timeSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [timeSlider.leadingAnchor constraintEqualToAnchor:timeSliderWrapperView.leadingAnchor constant:11.f],
        [timeSlider.trailingAnchor constraintEqualToAnchor:timeSliderWrapperView.trailingAnchor constant:-11.f],
        [timeSlider.centerYAnchor constraintEqualToAnchor:timeSliderWrapperView.centerYAnchor],
        [timeSlider.heightAnchor constraintEqualToConstant:22.f]
    ]];
}

- (void)layoutDurationLabelInStackView:(UIStackView *)stackView
{
    SRGControlWrapperView *durationLabelWrapperView = [[SRGControlWrapperView alloc] init];
    durationLabelWrapperView.matchingFirstSubviewHidden = YES;
    [stackView addArrangedSubview:durationLabelWrapperView];
    self.durationLabelWrapperView = durationLabelWrapperView;
    
    UILabel *durationLabel = [[UILabel alloc] init];
    durationLabel.textColor = UIColor.whiteColor;
    durationLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightRegular fixedSize:14.f];
    durationLabel.textAlignment = NSTextAlignmentCenter;
    [durationLabelWrapperView addSubview:durationLabel];
    self.durationLabel = durationLabel;
    
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [durationLabel.leadingAnchor constraintEqualToAnchor:durationLabelWrapperView.leadingAnchor constant:11.f],
        [durationLabel.trailingAnchor constraintEqualToAnchor:durationLabelWrapperView.trailingAnchor constant:-11.f],
        [durationLabel.centerYAnchor constraintEqualToAnchor:durationLabelWrapperView.centerYAnchor]
    ]];
}

- (void)layoutLiveLabelInStackView:(UIStackView *)stackView
{
    SRGControlWrapperView *liveLabelWrapperView = [[SRGControlWrapperView alloc] init];
    liveLabelWrapperView.matchingFirstSubviewHidden = YES;
    [stackView addArrangedSubview:liveLabelWrapperView];
    self.liveLabelWrapperView = liveLabelWrapperView;
    
    SRGLiveLabel *liveLabel = [[SRGLiveLabel alloc] init];
    [liveLabelWrapperView addSubview:liveLabel];
    self.liveLabel = liveLabel;
    
    liveLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [liveLabel.leadingAnchor constraintEqualToAnchor:liveLabelWrapperView.leadingAnchor constant:11.f],
        [liveLabel.trailingAnchor constraintEqualToAnchor:liveLabelWrapperView.trailingAnchor constant:-11.f],
        [liveLabel.centerYAnchor constraintEqualToAnchor:liveLabelWrapperView.centerYAnchor]
    ]];
}

- (void)layoutPlaybackSettingsButtonInStackView:(UIStackView *)stackView
{
    SRGPlaybackSettingsButton *playbackSettingsButton = [[SRGPlaybackSettingsButton alloc] init];
    playbackSettingsButton.tintColor = UIColor.whiteColor;
    playbackSettingsButton.delegate = self;
    [stackView addArrangedSubview:playbackSettingsButton];
    self.playbackSettingsButton = playbackSettingsButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [[playbackSettingsButton.widthAnchor constraintEqualToConstant:48.f] srgletterbox_withPriority:999]
    ]];
}

- (void)layoutFullScreenPhantomButtonInStackView:(UIStackView *)stackView
{
    // Always hidden from view. Only used to define the frame of the real full screen button, injected at the top of
    // the view hierarchy at runtime.
    SRGFullScreenButton *fullScreenPhantomButton = [[SRGFullScreenButton alloc] init];
    fullScreenPhantomButton.alpha = 0.f;
    [stackView addArrangedSubview:fullScreenPhantomButton];
    self.fullScreenPhantomButton = fullScreenPhantomButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [[fullScreenPhantomButton.widthAnchor constraintEqualToConstant:48.f] srgletterbox_withPriority:999]
    ]];
}

- (void)layoutCenterControlsInView:(UIView *)view
{
    [self layoutPlaybackButtonInView:view];
    [self layoutBackwardSkipButtonInView:view];
    [self layoutForwardSkipButtonInView:view];
    [self layoutStartOverButtonInView:view];
    [self layoutSkipToLiveButtonInView:view];
}

- (void)layoutPlaybackButtonInView:(UIView *)view
{
    SRGLetterboxPlaybackButton *playbackButton = [[SRGLetterboxPlaybackButton alloc] init];
    playbackButton.tintColor = UIColor.whiteColor;
    playbackButton.delegate = self;
    [view addSubview:playbackButton];
    self.playbackButton = playbackButton;
    
    playbackButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [playbackButton.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [playbackButton.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
}

- (void)layoutBackwardSkipButtonInView:(UIView *)view
{
    SRGLabeledControlButton *backwardSkipButton = [[SRGLabeledControlButton alloc] init];
    [backwardSkipButton setImage:[UIImage srg_letterboxImageNamed:@"backward"] forState:UIControlStateNormal];
    backwardSkipButton.tintColor = UIColor.whiteColor;
    backwardSkipButton.alpha = 0.f;
    [backwardSkipButton addTarget:self action:@selector(skipBackward:) forControlEvents:UIControlEventTouchUpInside];
    backwardSkipButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ backward", @"Seek backward button label with a custom time range"),
                                             [SRGControlsViewSkipIntervalAccessibilityFormatter() stringFromTimeInterval:SRGLetterboxSkipInterval]];
    [view addSubview:backwardSkipButton];
    self.backwardSkipButton = backwardSkipButton;
    
    backwardSkipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [backwardSkipButton.centerYAnchor constraintEqualToAnchor:self.playbackButton.centerYAnchor],
        self.horizontalSpacingSkipBackwardToPlaybackConstraint = [backwardSkipButton.centerXAnchor constraintEqualToAnchor:self.playbackButton.centerXAnchor],
    ]];
}

- (void)layoutForwardSkipButtonInView:(UIView *)view
{
    SRGLabeledControlButton *forwardSkipButton = [[SRGLabeledControlButton alloc] init];
    [forwardSkipButton setImage:[UIImage srg_letterboxImageNamed:@"forward"] forState:UIControlStateNormal];
    forwardSkipButton.tintColor = UIColor.whiteColor;
    forwardSkipButton.alpha = 0.f;
    [forwardSkipButton addTarget:self action:@selector(skipForward:) forControlEvents:UIControlEventTouchUpInside];
    forwardSkipButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ forward", @"Seek forward button label with a custom time range"),
                                            [SRGControlsViewSkipIntervalAccessibilityFormatter() stringFromTimeInterval:SRGLetterboxSkipInterval]];
    [view addSubview:forwardSkipButton];
    self.forwardSkipButton = forwardSkipButton;
    
    forwardSkipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [forwardSkipButton.centerYAnchor constraintEqualToAnchor:self.playbackButton.centerYAnchor],
        self.horizontalSpacingPlaybackToSkipForwardConstraint = [forwardSkipButton.centerXAnchor constraintEqualToAnchor:self.playbackButton.centerXAnchor]
    ]];
}

- (void)layoutStartOverButtonInView:(UIView *)view
{
    SRGControlButton *startOverButton = [[SRGControlButton alloc] init];
    [startOverButton setImage:[UIImage srg_letterboxStartOverImageInSet:SRGImageSetNormal] forState:UIControlStateNormal];
    startOverButton.tintColor = UIColor.whiteColor;
    startOverButton.alpha = 0.f;
    [startOverButton addTarget:self action:@selector(startOver:) forControlEvents:UIControlEventTouchUpInside];
    startOverButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Start over", @"Start over label");
    [view addSubview:startOverButton];
    self.startOverButton = startOverButton;
    
    startOverButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [startOverButton.centerYAnchor constraintEqualToAnchor:self.playbackButton.centerYAnchor],
        self.horizontalSpacingStartOverToPlaybackConstraint = [startOverButton.centerXAnchor constraintEqualToAnchor:self.playbackButton.centerXAnchor]
    ]];
}

- (void)layoutSkipToLiveButtonInView:(UIView *)view
{
    SRGLabeledControlButton *skipToLiveButton = [[SRGLabeledControlButton alloc] init];
    [skipToLiveButton setTitle:SRGLetterboxLocalizedString(@"Live", "Short live label displayed in the skip to live button").uppercaseString forState:UIControlStateNormal];
    [skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:SRGImageSetNormal] forState:UIControlStateNormal];
    skipToLiveButton.tintColor = UIColor.whiteColor;
    skipToLiveButton.alpha = 0.f;
    [skipToLiveButton addTarget:self action:@selector(skipToLive:) forControlEvents:UIControlEventTouchUpInside];
    skipToLiveButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Back to live", @"Back to live label");
    [view addSubview:skipToLiveButton];
    self.skipToLiveButton = skipToLiveButton;
    
    skipToLiveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [skipToLiveButton.centerYAnchor constraintEqualToAnchor:self.playbackButton.centerYAnchor],
        self.horizontalSpacingPlaybackToSkipToLiveConstraint = [skipToLiveButton.centerXAnchor constraintEqualToAnchor:self.playbackButton.centerXAnchor],
    ]];
}

#pragma mark Getters and setters

- (void)setUserInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle
{
    _userInterfaceStyle = userInterfaceStyle;
    self.playbackSettingsButton.userInterfaceStyle = userInterfaceStyle;
}

- (UIUserInterfaceStyle)userInterfaceStyle
{
    return _userInterfaceStyle;
}

- (CMTime)time
{
    return self.timeSlider.time;
}

- (NSDate *)date
{
    return self.timeSlider.date;
}

- (BOOL)isLive
{
    return self.timeSlider.live;
}

- (SRGImageSet)imageSet
{
    // The reference frame for controls is given by the available width (as occupied by the bottom stack view) as
    // well as the whole parent Letterbox height. Critical size is aligned on iPhone Plus devices in landscape.
    return (CGRectGetWidth(self.bottomStackView.frame) < 668.f || CGRectGetHeight(self.parentLetterboxView.frame) < 376.f) ? SRGImageSetNormal : SRGImageSetLarge;
}

- (CGFloat)skipControlsRadius
{
    return self.imageSet == SRGImageSetLarge ? kDistanceToCenterLargeUnit + kLargeIconDimension / 2.f : kDistanceToCenterNormalUnit + kNormalIconDimension / 2.f;
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        // Inject the full screen button as first Letterbox view. This ensures the button remains accessible at all times,
        // while its position is determined by a phantom button inserted in the bottom stack view.
        SRGLetterboxView *parentLetterboxView = self.parentLetterboxView;
        if (parentLetterboxView) {
            SRGFullScreenButton *fullScreenButton = [[SRGFullScreenButton alloc] init];
            fullScreenButton.tintColor = UIColor.whiteColor;
            fullScreenButton.selected = parentLetterboxView.fullScreen;
            [fullScreenButton addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
            [parentLetterboxView insertSubview:fullScreenButton atIndex:parentLetterboxView.subviews.count];
            self.fullScreenButton = fullScreenButton;
            
            fullScreenButton.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [fullScreenButton.topAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.topAnchor],
                [fullScreenButton.bottomAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.bottomAnchor],
                [fullScreenButton.leftAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.leftAnchor],
                [fullScreenButton.rightAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.rightAnchor]
            ]];
        }
    }
    else {
        [self.fullScreenButton removeFromSuperview];
    }
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGLetterboxController *controller = self.controller;
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    [mediaPlayerController removeObserver:self keyPath:@keypath(mediaPlayerController.timeRange)];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:SRGLetterboxPlaybackStateDidChangeNotification
                                                object:controller];
}

- (void)didDetachFromController
{
    [super didDetachFromController];
    
    self.playbackButton.controller = nil;
    
    self.pictureInPictureButton.mediaPlayerController = nil;
    self.airPlayButton.mediaPlayerController = nil;
    self.playbackSettingsButton.mediaPlayerController = nil;
    self.timeSlider.controller = nil;
    
    self.viewModeButton.mediaPlayerView = nil;
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    SRGLetterboxController *controller = self.controller;
    self.playbackButton.controller = controller;
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airPlayButton.mediaPlayerController = mediaPlayerController;
    self.playbackSettingsButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.controller = controller;
    
    self.viewModeButton.mediaPlayerView = mediaPlayerController.view;
    
    @weakify(self)
    [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.timeRange) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self setNeedsLayoutAnimated:YES];
    }];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playbackStateDidChange:)
                                               name:SRGLetterboxPlaybackStateDidChangeNotification
                                             object:self.controller];
    
    [self refresh];
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden transientState:(SRGLetterboxViewTransientState)transientState
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden transientState:transientState];
    
    SRGBlockingReason blockingReason = [self.controller.media blockingReasonAtDate:NSDate.date];
    BOOL hidden = userInterfaceHidden || blockingReason == SRGBlockingReasonStartDate || blockingReason == SRGBlockingReasonEndDate;
    self.alpha = (hidden && transientState == SRGLetterboxViewTransientStateNone) ? 0.f : 1.f;
    
    // General playback controls
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    if (playbackState == SRGMediaPlayerPlaybackStateIdle
            || playbackState == SRGMediaPlayerPlaybackStatePreparing
            || playbackState == SRGMediaPlayerPlaybackStateEnded) {
        self.playbackButton.alpha = (! hidden && ! self.controller.isLoading) ? 1.f : 0.f;
        self.durationLabel.alpha = 0.f;
        self.forwardSkipButton.alpha = 0.f;
        self.backwardSkipButton.alpha = 0.f;
        self.startOverButton.alpha = (! hidden && [self.controller canStartOver]) ? 1.f : 0.f;
        self.skipToLiveButton.alpha = (! hidden && [self.controller canSkipToLive]) ? 1.f : 0.f;
        self.timeSlider.alpha = 0.f;
    }
    else {
        SRGMediaPlayerStreamType streamType = self.controller.mediaPlayerController.streamType;
        BOOL canSeek = (streamType == SRGMediaPlayerStreamTypeOnDemand || streamType == SRGMediaPlayerStreamTypeDVR);
        
        self.playbackButton.alpha = (hidden || self.movingSlider || self.controller.loading) ? 0.f : 1.f;
        self.durationLabel.alpha = ! hidden ? 1.f : 0.f;
        
        self.forwardSkipButton.alpha = (! hidden && ! self.movingSlider && canSeek) || transientState == SRGLetterboxViewTransientStateDoubleTapSkippingForward ? 1.f : 0.f;
        self.forwardSkipButton.enabled = [self.controller canSkipWithInterval:SRGLetterboxSkipInterval];
        
        self.backwardSkipButton.alpha = (! hidden && ! self.movingSlider && canSeek) || transientState == SRGLetterboxViewTransientStateDoubleTapSkippingBackward ? 1.f : 0.f;
        self.backwardSkipButton.enabled = [self.controller canSkipWithInterval:-SRGLetterboxSkipInterval];
        
        self.startOverButton.alpha = ! hidden && ! self.movingSlider && streamType == SRGMediaPlayerStreamTypeDVR && self.controller.mediaComposition.mainChapter.segments != 0 ? 1.f : 0.f;
        self.startOverButton.enabled = [self.controller canStartOver];
        
        BOOL canSkipToLive = [self.controller canSkipToLive];
        self.skipToLiveButton.alpha = ! hidden && ! self.movingSlider && (streamType == SRGMediaPlayerStreamTypeDVR || canSkipToLive) ? 1.f : 0.f;
        self.skipToLiveButton.enabled = canSkipToLive;
        
        self.timeSlider.alpha = ! hidden && canSeek ? 1.f : 0.f;
    }
    
    SRGLetterboxView *parentLetterboxView = self.parentLetterboxView;
    self.fullScreenButton.alpha = ! hidden && (parentLetterboxView.minimal || ! userInterfaceHidden) ? 1.f : 0.f;
    self.fullScreenButton.selected = parentLetterboxView.fullScreen;
    
    self.pictureInPictureButton.alpha = ! hidden ? 1.f : 0.f;
    self.playbackSettingsButton.alpha = ! hidden ? 1.f : 0.f;
    self.airPlayButton.alpha = ! hidden ? 1.f : 0.f;
    
    BOOL isLarge = (self.imageSet == SRGImageSetLarge);
    
    CGFloat distanceToCenter = isLarge ? kDistanceToCenterLargeUnit : kDistanceToCenterNormalUnit;
    CGFloat doubleTapOffset = isLarge ? 30.f : 15.f;
    
    CGFloat backwardOffset = (transientState == SRGLetterboxViewTransientStateDoubleTapSkippingBackward ? doubleTapOffset : 0.f);
    CGFloat forwardOffset = (transientState == SRGLetterboxViewTransientStateDoubleTapSkippingForward ? doubleTapOffset : 0.f);
    
    self.horizontalSpacingStartOverToPlaybackConstraint.constant = - 2 * distanceToCenter;
    self.horizontalSpacingSkipBackwardToPlaybackConstraint.constant = -distanceToCenter - backwardOffset;
    self.horizontalSpacingPlaybackToSkipForwardConstraint.constant = distanceToCenter + forwardOffset;
    self.horizontalSpacingPlaybackToSkipToLiveConstraint.constant = 2 * distanceToCenter;
    
    [self.backwardSkipButton srg_letterboxSetShadowHidden:! userInterfaceHidden];
    [self.forwardSkipButton srg_letterboxSetShadowHidden:! userInterfaceHidden];
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden transientState:(SRGLetterboxViewTransientState)transientState
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden transientState:transientState];
    
    // General playback controls
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    SRGMediaPlayerStreamType streamType = self.controller.mediaPlayerController.streamType;
    self.durationLabel.hidden = (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStateEnded || playbackState == SRGMediaPlayerPlaybackStatePreparing
                                 || streamType != SRGStreamTypeOnDemand);
    self.liveLabel.hidden = (streamType != SRGStreamTypeLive || playbackState == SRGMediaPlayerPlaybackStateIdle);
    
    SRGImageSet imageSet = self.imageSet;
    self.playbackButton.imageSet = imageSet;
    
    CGFloat skipLabelFontSize = (imageSet == SRGImageSetLarge) ? 18.f : 14.f;
    UIFont *skipLabelFont = [SRGFont fontWithFamily:SRGFontFamilyText weight:UIFontWeightHeavy fixedSize:skipLabelFontSize];
    
    self.backwardSkipButton.titleLabel.font = skipLabelFont;
    self.backwardSkipButton.verticalOffset = skipLabelFontSize;
    
    self.forwardSkipButton.titleLabel.font = skipLabelFont;
    self.forwardSkipButton.verticalOffset = skipLabelFontSize;
    
    self.skipToLiveButton.titleLabel.font = skipLabelFont;
    self.skipToLiveButton.verticalOffset = skipLabelFontSize;
    
    switch (transientState) {
        case SRGLetterboxViewTransientStateNone: {
            [self.backwardSkipButton setTitle:[NSString stringWithFormat:@"%@S", @(SRGLetterboxSkipInterval)] forState:UIControlStateNormal];
            [self.forwardSkipButton setTitle:[NSString stringWithFormat:@"%@S", @(SRGLetterboxSkipInterval)] forState:UIControlStateNormal];
            break;
        }
            
        case SRGLetterboxViewTransientStateDoubleTapSkippingBackward: {
            [self.backwardSkipButton setTitle:[NSString stringWithFormat:@"-%@S", @(self.parentLetterboxView.doubleTapSkipCount * SRGLetterboxSkipInterval)] forState:UIControlStateNormal];
            [self.forwardSkipButton setTitle:[NSString stringWithFormat:@"%@S", @(SRGLetterboxSkipInterval)] forState:UIControlStateNormal];
            break;
        }
        
        case SRGLetterboxViewTransientStateDoubleTapSkippingForward: {
            [self.backwardSkipButton setTitle:[NSString stringWithFormat:@"%@S", @(SRGLetterboxSkipInterval)] forState:UIControlStateNormal];
            [self.forwardSkipButton setTitle:[NSString stringWithFormat:@"+%@S", @(self.parentLetterboxView.doubleTapSkipCount * SRGLetterboxSkipInterval)] forState:UIControlStateNormal];
            break;
        }
    }
    
    [self.backwardSkipButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSkipButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.startOverButton setImage:[UIImage srg_letterboxStartOverImageInSet:imageSet] forState:UIControlStateNormal];
    [self.skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:imageSet] forState:UIControlStateNormal];
    
    // Show or hide the phantom button in the controls stack, as the real full-screen button will follow its frame
    self.fullScreenPhantomButton.hidden = [self.delegate controlsViewShouldHideFullScreenButton:self];
    
    // Responsiveness
    self.backwardSkipButton.hidden = NO;
    self.forwardSkipButton.hidden = NO;
    self.startOverButton.hidden = NO;
    self.skipToLiveButton.hidden = NO;
    self.timeSlider.hidden = NO;
    self.durationLabelWrapperView.alwaysHidden = NO;
    self.viewModeButton.alwaysHidden = NO;
    self.pictureInPictureButton.alwaysHidden = ! self.controller.pictureInPictureEnabled;
    self.liveLabelWrapperView.alwaysHidden = NO;
    self.playbackSettingsButton.hidden = NO;
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 167.f) {
        self.timeSlider.hidden = YES;
        self.durationLabelWrapperView.alwaysHidden = YES;
    }
    if (height < 120.f) {
        self.backwardSkipButton.hidden = YES;
        self.forwardSkipButton.hidden = YES;
        self.startOverButton.hidden = YES;
        self.skipToLiveButton.hidden = YES;
        self.viewModeButton.alwaysHidden = YES;
        self.pictureInPictureButton.alwaysHidden = YES;
        self.liveLabelWrapperView.alwaysHidden = YES;
        self.playbackSettingsButton.hidden = YES;
    }
    
    CGFloat width = CGRectGetWidth(self.frame);
    if (width < 320.f) {
        self.durationLabelWrapperView.alwaysHidden = YES;
    }
    if (width < 296.f) {
        self.startOverButton.hidden = YES;
        self.skipToLiveButton.hidden = YES;
        self.timeSlider.hidden = YES;
    }
    if (width < 214.f) {
        self.backwardSkipButton.hidden = YES;
        self.forwardSkipButton.hidden = YES;
        self.viewModeButton.alwaysHidden = YES;
        self.pictureInPictureButton.alwaysHidden = YES;
        self.liveLabelWrapperView.alwaysHidden = YES;
        self.playbackSettingsButton.hidden = YES;
    }
    
    // Fix incorrect empty space after hiding the full screen button on iOS 9.
    NSOperatingSystemVersion operatingSystemVersion = NSProcessInfo.processInfo.operatingSystemVersion;
    if (operatingSystemVersion.majorVersion == 9) {
        [self.bottomStackView setNeedsLayout];
        [self.bottomStackView layoutIfNeeded];
    }
    
    self.airPlayButton.alwaysHidden = (SRGLetterboxService.sharedService.controller != self.controller);
}

#pragma mark UI

- (void)refresh
{
    CMTimeRange timeRange = self.controller.timeRange;
    if (SRG_CMTIMERANGE_IS_DEFINITE(timeRange) && SRG_CMTIMERANGE_IS_NOT_EMPTY(timeRange)) {
        NSTimeInterval durationInSeconds = CMTimeGetSeconds(timeRange.duration);
        if (durationInSeconds < 60. * 60.) {
            self.durationLabel.text = [NSDateComponentsFormatter.srg_shortDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
        }
        else {
            self.durationLabel.text = [NSDateComponentsFormatter.srg_mediumDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
        }
        
        self.durationLabel.accessibilityLabel = [NSDateComponentsFormatter.srg_accessibilityDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
    }
    else {
        self.durationLabel.text = nil;
        self.durationLabel.accessibilityLabel = nil;
    }
}

#pragma mark SRGLetterboxTimeSliderDelegate protocol

- (void)timeSlider:(SRGLetterboxTimeSlider *)slider isMovingToTime:(CMTime)time date:(NSDate *)date withValue:(float)value interactive:(BOOL)interactive
{
    [self.delegate controlsView:self isMovingSliderToTime:time date:date withValue:value interactive:interactive];
}

- (void)timeSlider:(SRGLetterboxTimeSlider *)slider didStartDraggingAtTime:(CMTime)time date:(NSDate *)date withValue:(float)value
{
    self.movingSlider = YES;
}

- (void)timeSlider:(SRGLetterboxTimeSlider *)slider didStopDraggingAtTime:(CMTime)time date:(NSDate *)date withValue:(float)value
{
    self.movingSlider = NO;
}

#pragma mark SRGPlaybackButtonDelegate protocol

- (void)playbackButton:(SRGLetterboxPlaybackButton *)playbackButton didTogglePlayPause:(BOOL)paused
{
    [self.delegate controlsView:self didTogglePlayPause:paused];
}

#pragma mark SRGPlaybackSettingsButtonDelegate protocol

- (void)playbackSettingsButton:(SRGPlaybackSettingsButton *)playbackSettingsButton didSelectPlaybackRate:(float)playbackRate
{
    [self.delegate controlsView:self didSelectPlaybackRate:playbackRate];
}

- (void)playbackSettingsButton:(SRGPlaybackSettingsButton *)playbackSettingsButton didSelectAudioLanguageCode:(NSString *)languageCode
{
    [self.delegate controlsView:self didSelectAudioLanguageCode:languageCode];
}

- (void)playbackSettingsButton:(SRGPlaybackSettingsButton *)playbackSettingsButton didSelectSubtitleLanguageCode:(NSString *)languageCode
{
    [self.delegate controlsView:self didSelectSubtitleLanguageCode:languageCode];
}

- (void)playbackSettingsButtonWillShowSettings:(SRGPlaybackSettingsButton *)playbackSettingsButton
{
    [self.delegate controlsViewWillShowPlaybackSettings:self];
}

- (void)playbackSettingsButtonDidHideSettings:(SRGPlaybackSettingsButton *)playbackSettingsButton
{
    [self.delegate controlsViewDidHidePlaybackSettings:self];
}

#pragma mark Actions

- (void)skipBackward:(id)sender
{
    [self.controller skipWithInterval:-SRGLetterboxSkipInterval completionHandler:nil];
}

- (void)skipForward:(id)sender
{
    [self.controller skipWithInterval:SRGLetterboxSkipInterval completionHandler:nil];
}

- (void)startOver:(id)sender
{
    [self.controller startOverWithCompletionHandler:nil];
}

- (void)skipToLive:(id)sender
{
    [self.controller skipToLiveWithCompletionHandler:nil];
}

- (void)toggleFullScreen:(id)sender
{
    [self.delegate controlsViewDidToggleFullScreen:self];
}

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self refresh];
}

@end

#endif
