//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGControlsView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSLayoutConstraint+SRGLetterboxPrivate.h"
#import "SRGControlButton.h"
#import "SRGControlWrapperView.h"
#import "SRGFullScreenButton.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxService.h"
#import "SRGLetterboxPlaybackButton.h"
#import "SRGLetterboxTimeSlider.h"
#import "SRGLetterboxView+Private.h"
#import "SRGLiveLabel.h"
#import "UIFont+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

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
@property (nonatomic, weak) SRGControlButton *backwardSeekButton;
@property (nonatomic, weak) SRGControlButton *forwardSeekButton;
@property (nonatomic, weak) SRGControlButton *startOverButton;
@property (nonatomic, weak) SRGControlButton *skipToLiveButton;

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

@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingBackwardToPlaybackConstraint;
@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingPlaybackToForwardConstraint;
@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingForwardToSkipToLiveConstraint;
@property (nonatomic, weak) NSLayoutConstraint *horizontalSpacingStartOverToBackwardConstraint;

@property (nonatomic, weak) SRGFullScreenButton *fullScreenButton;

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
    userInterfaceToggleActiveView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:userInterfaceToggleActiveView];
    self.userInterfaceToggleActiveView = userInterfaceToggleActiveView;
    
    [NSLayoutConstraint activateConstraints:@[
        [userInterfaceToggleActiveView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [userInterfaceToggleActiveView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [userInterfaceToggleActiveView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
    ]];
    
    UITapGestureRecognizer *hideUserInterfaceTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideUserInterface:)];
    [userInterfaceToggleActiveView addGestureRecognizer:hideUserInterfaceTapGestureRecognizer];
}

- (void)layoutBottomControlsInView:(UIView *)view
{
    UIStackView *bottomStackView = [[UIStackView alloc] init];
    bottomStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:bottomStackView];
    self.bottomStackView = bottomStackView;
    
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
    timeSlider.translatesAutoresizingMaskIntoConstraints = NO;
    timeSlider.alpha = 0.f;
    timeSlider.minimumTrackTintColor = UIColor.whiteColor;
    timeSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.f alpha:0.3f];
    timeSlider.bufferingTrackColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    timeSlider.resumingAfterSeek = YES;
    timeSlider.delegate = self;
    [timeSliderWrapperView addSubview:timeSlider];
    self.timeSlider = timeSlider;
    
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
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    durationLabel.textColor = UIColor.whiteColor;
    durationLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightRegular fixedSize:14.f];
    durationLabel.textAlignment = NSTextAlignmentCenter;
    [durationLabelWrapperView addSubview:durationLabel];
    self.durationLabel = durationLabel;
    
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
    liveLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [liveLabelWrapperView addSubview:liveLabel];
    self.liveLabel = liveLabel;
    
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
    [self layoutBackwardSeekButtonInView:view];
    [self layoutForwardSeekButtonInView:view];
    [self layoutStartOverButtonInView:view];
    [self layoutSkipToLiveButtonInView:view];
}

- (void)layoutPlaybackButtonInView:(UIView *)view
{
    SRGLetterboxPlaybackButton *playbackButton = [[SRGLetterboxPlaybackButton alloc] init];
    playbackButton.translatesAutoresizingMaskIntoConstraints = NO;
    playbackButton.tintColor = UIColor.whiteColor;
    [view addSubview:playbackButton];
    self.playbackButton = playbackButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [playbackButton.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [playbackButton.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
}

- (void)layoutBackwardSeekButtonInView:(UIView *)view
{
    SRGControlButton *backwardSeekButton = [[SRGControlButton alloc] init];
    backwardSeekButton.translatesAutoresizingMaskIntoConstraints = NO;
    [backwardSeekButton setImage:[UIImage srg_letterboxImageNamed:@"backward"] forState:UIControlStateNormal];
    backwardSeekButton.tintColor = UIColor.whiteColor;
    backwardSeekButton.alpha = 0.f;
    [backwardSeekButton addTarget:self action:@selector(skipBackward:) forControlEvents:UIControlEventTouchUpInside];
    backwardSeekButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ backward", @"Seek backward button label with a custom time range"),
                                             [SRGControlsViewSkipIntervalAccessibilityFormatter() stringFromTimeInterval:SRGLetterboxBackwardSkipInterval]];
    [view addSubview:backwardSeekButton];
    self.backwardSeekButton = backwardSeekButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [backwardSeekButton.centerYAnchor constraintEqualToAnchor:self.playbackButton.centerYAnchor],
        self.horizontalSpacingBackwardToPlaybackConstraint = [self.playbackButton.leadingAnchor constraintEqualToAnchor:backwardSeekButton.trailingAnchor],
    ]];
}

- (void)layoutForwardSeekButtonInView:(UIView *)view
{
    SRGControlButton *forwardSeekButton = [[SRGControlButton alloc] init];
    forwardSeekButton.translatesAutoresizingMaskIntoConstraints = NO;
    [forwardSeekButton setImage:[UIImage srg_letterboxImageNamed:@"forward"] forState:UIControlStateNormal];
    forwardSeekButton.tintColor = UIColor.whiteColor;
    forwardSeekButton.alpha = 0.f;
    [forwardSeekButton addTarget:self action:@selector(skipForward:) forControlEvents:UIControlEventTouchUpInside];
    forwardSeekButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ forward", @"Seek forward button label with a custom time range"),
                                            [SRGControlsViewSkipIntervalAccessibilityFormatter() stringFromTimeInterval:SRGLetterboxForwardSkipInterval]];
    [view addSubview:forwardSeekButton];
    self.forwardSeekButton = forwardSeekButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [forwardSeekButton.centerYAnchor constraintEqualToAnchor:self.playbackButton.centerYAnchor],
        self.horizontalSpacingPlaybackToForwardConstraint = [forwardSeekButton.leadingAnchor constraintEqualToAnchor:self.playbackButton.trailingAnchor]
    ]];
}

- (void)layoutStartOverButtonInView:(UIView *)view
{
    SRGControlButton *startOverButton = [[SRGControlButton alloc] init];
    startOverButton.translatesAutoresizingMaskIntoConstraints = NO;
    [startOverButton setImage:[UIImage srg_letterboxStartOverImageInSet:SRGImageSetNormal] forState:UIControlStateNormal];
    startOverButton.tintColor = UIColor.whiteColor;
    startOverButton.alpha = 0.f;
    [startOverButton addTarget:self action:@selector(startOver:) forControlEvents:UIControlEventTouchUpInside];
    startOverButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Start over", @"Start over label");
    [view addSubview:startOverButton];
    self.startOverButton = startOverButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [startOverButton.centerYAnchor constraintEqualToAnchor:self.backwardSeekButton.centerYAnchor],
        self.horizontalSpacingStartOverToBackwardConstraint = [self.backwardSeekButton.leadingAnchor constraintEqualToAnchor:startOverButton.trailingAnchor]
    ]];
}

- (void)layoutSkipToLiveButtonInView:(UIView *)view
{
    SRGControlButton *skipToLiveButton = [[SRGControlButton alloc] init];
    skipToLiveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:SRGImageSetNormal] forState:UIControlStateNormal];
    skipToLiveButton.tintColor = UIColor.whiteColor;
    skipToLiveButton.alpha = 0.f;
    [skipToLiveButton addTarget:self action:@selector(skipToLive:) forControlEvents:UIControlEventTouchUpInside];
    skipToLiveButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Back to live", @"Back to live label");
    [view addSubview:skipToLiveButton];
    self.skipToLiveButton = skipToLiveButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [skipToLiveButton.centerYAnchor constraintEqualToAnchor:self.forwardSeekButton.centerYAnchor],
        self.horizontalSpacingForwardToSkipToLiveConstraint = [skipToLiveButton.leadingAnchor constraintEqualToAnchor:self.forwardSeekButton.trailingAnchor],
    ]];
}

#pragma mark Getters and setters

- (void)setUserInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle
{
    _userInterfaceStyle = userInterfaceStyle;
    self.playbackSettingsButton.userInterfaceStyle = userInterfaceStyle;
}

- (SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle
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

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        // Inject the full screen button as first Letterbox view. This ensures the button remains accessible at all times,
        // while its position is determined by a phantom button inserted in the bottom stack view.
        SRGLetterboxView *parentLetterboxView = self.parentLetterboxView;
        if (parentLetterboxView) {
            SRGFullScreenButton *fullScreenButton = [[SRGFullScreenButton alloc] initWithFrame:CGRectZero];
            fullScreenButton.tintColor = UIColor.whiteColor;
            fullScreenButton.selected = parentLetterboxView.fullScreen;
            [fullScreenButton addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
            [parentLetterboxView insertSubview:fullScreenButton atIndex:parentLetterboxView.subviews.count];
            self.fullScreenButton = fullScreenButton;
            
            fullScreenButton.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[ [fullScreenButton.topAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.topAnchor],
                                                       [fullScreenButton.bottomAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.bottomAnchor],
                                                       [fullScreenButton.leftAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.leftAnchor],
                                                       [fullScreenButton.rightAnchor constraintEqualToAnchor:self.fullScreenPhantomButton.rightAnchor] ]];
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
    self.timeSlider.mediaPlayerController = nil;
    
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
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
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

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    SRGBlockingReason blockingReason = [self.controller.media blockingReasonAtDate:NSDate.date];
    self.alpha = (! userInterfaceHidden && blockingReason != SRGBlockingReasonStartDate && blockingReason != SRGBlockingReasonEndDate) ? 1.f : 0.f;
    
    // General playback controls
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    if (playbackState == SRGMediaPlayerPlaybackStateIdle
        || playbackState == SRGMediaPlayerPlaybackStatePreparing
        || playbackState == SRGMediaPlayerPlaybackStateEnded) {
        self.forwardSeekButton.alpha = 0.f;
        self.backwardSeekButton.alpha = 0.f;
        self.startOverButton.alpha = [self.controller canStartOver] ? 1.f : 0.f;
        self.skipToLiveButton.alpha = [self.controller canSkipToLive] ? 1.f : 0.f;
        
        self.timeSlider.alpha = 0.f;
    }
    else {
        SRGMediaPlayerStreamType streamType = self.controller.mediaPlayerController.streamType;
        BOOL canSeek = (streamType == SRGMediaPlayerStreamTypeOnDemand || streamType == SRGMediaPlayerStreamTypeDVR);
        
        self.forwardSeekButton.alpha = canSeek ? 1.f : 0.f;
        self.forwardSeekButton.enabled = [self.controller canSkipWithInterval:SRGLetterboxForwardSkipInterval];
        
        self.backwardSeekButton.alpha = canSeek ? 1.f : 0.f;
        self.backwardSeekButton.enabled = [self.controller canSkipWithInterval:-SRGLetterboxBackwardSkipInterval];
        
        self.startOverButton.alpha = (streamType == SRGMediaPlayerStreamTypeDVR && self.controller.mediaComposition.mainChapter.segments != 0) ? 1.f : 0.f;
        self.startOverButton.enabled = [self.controller canStartOver];
        
        BOOL canSkipToLive = [self.controller canSkipToLive];
        self.skipToLiveButton.alpha = (streamType == SRGMediaPlayerStreamTypeDVR || canSkipToLive) ? 1.f : 0.f;
        self.skipToLiveButton.enabled = canSkipToLive;
        
        self.timeSlider.alpha = canSeek ? 1.f : 0.f;
    }
    
    self.playbackButton.alpha = self.controller.loading ? 0.f : 1.f;
    
    SRGLetterboxView *parentLetterboxView = self.parentLetterboxView;
    self.fullScreenButton.alpha = (parentLetterboxView.minimal || ! userInterfaceHidden) ? 1.f : 0.f;
    self.fullScreenButton.selected = parentLetterboxView.fullScreen;
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    SRGBlockingReason blockingReason = [self.controller.media blockingReasonAtDate:NSDate.date];
    self.alpha = (! userInterfaceHidden && blockingReason != SRGBlockingReasonStartDate && blockingReason != SRGBlockingReasonEndDate && ! self.controller.continuousPlaybackUpcomingMedia) ? 1.f : 0.f;
    
    // General playback controls
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    SRGMediaPlayerStreamType streamType = self.controller.mediaPlayerController.streamType;
    self.durationLabel.hidden = (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStateEnded || playbackState == SRGMediaPlayerPlaybackStatePreparing
                                 || streamType != SRGStreamTypeOnDemand);
    self.liveLabel.hidden = (streamType != SRGStreamTypeLive || playbackState == SRGMediaPlayerPlaybackStateIdle);
    
    // The reference frame for controls is given by the available width (as occupied by the bottom stack view) as
    // well as the whole parent Letterbox height. Critical size is aligned on iPhone Plus devices in landscape.
    SRGImageSet imageSet = (CGRectGetWidth(self.bottomStackView.frame) < 668.f || CGRectGetHeight(self.parentLetterboxView.frame) < 376.f) ? SRGImageSetNormal : SRGImageSetLarge;
    CGFloat horizontalSpacing = (imageSet == SRGImageSetNormal) ? 16.f : 36.f;
    
    self.horizontalSpacingBackwardToPlaybackConstraint.constant = horizontalSpacing;
    self.horizontalSpacingPlaybackToForwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingForwardToSkipToLiveConstraint.constant = horizontalSpacing;
    self.horizontalSpacingStartOverToBackwardConstraint.constant = horizontalSpacing;
    
    self.playbackButton.imageSet = imageSet;
    
    [self.backwardSeekButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSeekButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.startOverButton setImage:[UIImage srg_letterboxStartOverImageInSet:imageSet] forState:UIControlStateNormal];
    [self.skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:imageSet] forState:UIControlStateNormal];
    
    // Show or hide the phantom button in the controls stack, as the real full-screen button will follow its frame
    self.fullScreenPhantomButton.hidden = [self.delegate controlsViewShouldHideFullScreenButton:self];
    
    // Responsiveness
    self.backwardSeekButton.hidden = NO;
    self.forwardSeekButton.hidden = NO;
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
        self.backwardSeekButton.hidden = YES;
        self.forwardSeekButton.hidden = YES;
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
        self.backwardSeekButton.hidden = YES;
        self.forwardSeekButton.hidden = YES;
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

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToTime:(CMTime)time date:(NSDate *)date withValue:(float)value interactive:(BOOL)interactive
{
    [self.delegate controlsView:self isMovingSliderToTime:time date:date withValue:value interactive:interactive];
}

- (NSAttributedString *)timeSlider:(SRGTimeSlider *)slider labelForValue:(float)value time:(CMTime)time date:(NSDate *)date
{
    SRGMediaPlayerStreamType streamType = slider.mediaPlayerController.streamType;
    if (slider.live) {
        return [[NSAttributedString alloc] initWithString:SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live only stream or a DVR stream in live").uppercaseString attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightBold fixedSize:14.f] }];
    }
    else if (streamType == SRGMediaPlayerStreamTypeDVR) {
        if (date) {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@" ") attributes:@{ NSFontAttributeName : [UIFont srg_awesomeFontWithSize:14.f] }];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSDateFormatter.srgletterbox_timeFormatter stringFromDate:date] attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:14.f] }]];
            return attributedString.copy;
        }
        else {
            return [[NSAttributedString alloc] initWithString:@"--:--" attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:14.f] }];
        }
    }
    else if (streamType == SRGMediaPlayerStreamTypeLive) {
        return nil;
    }
    else {
        NSDateComponentsFormatter *dateComponentsFormatter = (fabsf(value) < 60.f * 60.f) ? NSDateComponentsFormatter.srg_shortDateComponentsFormatter : NSDateComponentsFormatter.srg_mediumDateComponentsFormatter;
        NSString *string = [dateComponentsFormatter stringFromTimeInterval:value];
        return [[NSAttributedString alloc] initWithString:string attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:14.f] }];
    }
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
    [self.controller skipWithInterval:-SRGLetterboxBackwardSkipInterval completionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToTime:self.timeSlider.time date:self.timeSlider.date withValue:self.timeSlider.value interactive:YES];
    }];
}

- (void)skipForward:(id)sender
{
    [self.controller skipWithInterval:SRGLetterboxForwardSkipInterval completionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToTime:self.timeSlider.time date:self.timeSlider.date withValue:self.timeSlider.value interactive:YES];
    }];
}

- (void)startOver:(id)sender
{
    [self.controller startOverWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToTime:self.timeSlider.time date:self.timeSlider.date withValue:self.timeSlider.value interactive:YES];
    }];
}

- (void)skipToLive:(id)sender
{
    [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToTime:self.timeSlider.time date:self.timeSlider.date withValue:self.timeSlider.value interactive:YES];
    }];
}

- (void)hideUserInterface:(id)sender
{
    [self.delegate controlsViewDidTap:self];
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
