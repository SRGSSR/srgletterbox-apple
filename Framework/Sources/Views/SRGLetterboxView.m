//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"
#import "SRGLetterboxView+Private.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGAccessibilityView.h"
#import "SRGContinuousPlaybackView.h"
#import "SRGControlsView.h"
#import "SRGCountdownView.h"
#import "SRGFullScreenButton.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxLogger.h"
#import "SRGLetterboxPlaybackButton.h"
#import "SRGLetterboxService+Private.h"
#import "SRGLetterboxTimelineView.h"
#import "SRGLetterboxTimeSlider.h"
#import "SRGProgram+SRGLetterbox.h"
#import "SRGTapGestureRecognizer.h"
#import "UIFont+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGAppearance/SRGAppearance.h>
#import <libextobjc/libextobjc.h>
#import <Masonry/Masonry.h>

const CGFloat SRGLetterboxViewDefaultTimelineHeight = 120.f;

static void commonInit(SRGLetterboxView *self);

@interface SRGLetterboxView () <SRGLetterboxTimelineViewDelegate, SRGContinuousPlaybackViewDelegate, SRGControlsViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineToSafeAreaBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineToSuperviewBottomConstraint;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray<NSLayoutConstraint *> *controlsStackToSafeAreaEdgeConstraints;
@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray<NSLayoutConstraint *> *controlsStackToSuperviewEdgeConstraints;

@property (nonatomic, weak) IBOutlet SRGControlsView *controlsView;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray<NSLayoutConstraint *> *controlsToSuperviewEdgeConstraints;
@property (nonatomic, weak) IBOutlet SRGLetterboxPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *forwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *skipToLiveButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToBackwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToForwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingForwardToSkipToLiveConstraint;

@property (nonatomic, weak) IBOutlet SRGAccessibilityView *accessibilityView;

@property (nonatomic, weak) UIImageView *loadingImageView;

@property (nonatomic, weak) IBOutlet UIView *errorView;
@property (nonatomic, weak) IBOutlet UIImageView *errorImageView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;
@property (nonatomic, weak) IBOutlet UILabel *errorInstructionsLabel;

@property (nonatomic, weak) IBOutlet UIView *availabilityView;
@property (nonatomic, weak) IBOutlet SRGCountdownView *countdownView;
@property (nonatomic, weak) IBOutlet UIView *availabilityLabelBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *availabilityLabel;

@property (nonatomic, weak) IBOutlet UIView *continuousPlaybackWrapperView;
@property (nonatomic, weak) IBOutlet SRGContinuousPlaybackView *continuousPlaybackView;

@property (nonatomic) NSTimer *userInterfaceUpdateTimer;

@property (nonatomic, weak) IBOutlet SRGViewModeButton *viewModeButton;
@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet SRGLetterboxTimeSlider *timeSlider;
@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;

@property (nonatomic, weak) IBOutlet UILabel *durationLabel;

@property (nonatomic) IBOutletCollection(SRGFullScreenButton) NSArray<SRGFullScreenButton *> *fullScreenButtons;

@property (nonatomic, weak) IBOutlet UIView *notificationView;
@property (nonatomic, weak) IBOutlet UIImageView *notificationImageView;
@property (nonatomic, weak) IBOutlet UILabel *notificationLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *notificationLabelTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *notificationLabelBottomConstraint;

@property (nonatomic, weak) IBOutlet SRGLetterboxTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineHeightConstraint;

@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *showUserInterfaceTapGestureRecognizer;
@property (nonatomic, weak) IBOutlet SRGTapGestureRecognizer *videoGravityTapChangeGestureRecognizer;

@property (nonatomic) NSTimer *inactivityTimer;

@property (nonatomic, copy) NSString *notificationMessage;

@property (nonatomic, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;
@property (nonatomic, getter=isUserInterfaceTogglable) BOOL userInterfaceTogglable;

@property (nonatomic, getter=isFullScreen) BOOL fullScreen;
@property (nonatomic, getter=isFullScreenAnimationRunning) BOOL fullScreenAnimationRunning;

@property (nonatomic) CGFloat preferredTimelineHeight;

@property (nonatomic, copy) void (^animations)(BOOL hidden, CGFloat heightOffset);
@property (nonatomic, copy) void (^completion)(BOOL finished);

@property (nonatomic, copy) AVLayerVideoGravity targetVideoGravity;

@end

@implementation SRGLetterboxView {
@private
    BOOL _inWillAnimateUserInterface;
}

#pragma mark Class methods

+ (void)setMotionManager:(CMMotionManager *)motionManager
{
    [SRGMediaPlayerView setMotionManager:motionManager];
}

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
        
        // The top-level view loaded from the xib file and initialized in `commonInit` is NOT an SRGLetterboxView. Manually
        // calling `-awakeFromNib` forces the final view initialization (also see comments in `commonInit`).
        [self awakeFromNib];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

- (void)dealloc
{
    self.controller = nil;                   // Unregister everything
}

#pragma mark View lifecycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIImageView *loadingImageView = [UIImageView srg_loadingImageView48WithTintColor:[UIColor whiteColor]];
    loadingImageView.alpha = 0.f;
    [self.mainView insertSubview:loadingImageView aboveSubview:self.playbackButton];
    [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.playbackButton.mas_centerX);
        make.centerY.equalTo(self.playbackButton.mas_centerY);
    }];
    self.loadingImageView = loadingImageView;
    
    self.errorImageView.image = nil;
    self.errorImageView.hidden = YES;
    
    self.errorInstructionsLabel.accessibilityTraits = UIAccessibilityTraitButton;
    
    self.backwardSeekButton.alpha = 0.f;
    self.forwardSeekButton.alpha = 0.f;
    self.skipToLiveButton.alpha = 0.f;
    self.timeSlider.alpha = 0.f;
    self.timeSlider.timeLeftValueLabel.hidden = YES;
    self.availabilityView.alpha = 0.f;
    
    self.errorView.hidden = YES;
    
    self.accessibilityView.letterboxView = self;
    self.accessibilityView.alpha = UIAccessibilityIsVoiceOverRunning() ? 1.f : 0.f;
    
    self.controlsView.delegate = self;
    self.timelineView.delegate = self;
    
    self.timeSlider.resumingAfterSeek = NO;
    self.timeSlider.delegate = self;
    
    self.timelineHeightConstraint.constant = 0.f;
    
    self.airplayButton.image = [UIImage imageNamed:@"airplay-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.pictureInPictureButton.startImage = [UIImage imageNamed:@"picture_in_picture_start-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.pictureInPictureButton.stopImage = [UIImage imageNamed:@"picture_in_picture_stop-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.tracksButton.image = [UIImage imageNamed:@"subtitles_off-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    self.tracksButton.selectedImage = [UIImage imageNamed:@"subtitles_on-48" inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
    
    // Workaround UIImage view tint color bug
    // See http://stackoverflow.com/a/26042893/760435
    UIImage *notificationImage = self.notificationImageView.image;
    self.notificationImageView.image = nil;
    self.notificationImageView.image = notificationImage;
    self.notificationLabel.text = nil;
    self.notificationImageView.hidden = YES;
    
    // Detect all touches on the player view. Other gesture recognizers can be added directly in the storyboard
    // to detect other interactions earlier
    SRGActivityGestureRecognizer *activityGestureRecognizer = [[SRGActivityGestureRecognizer alloc] initWithTarget:self
                                                                                                            action:@selector(resetInactivityTimer:)];
    activityGestureRecognizer.delegate = self;
    [self.mainView addGestureRecognizer:activityGestureRecognizer];
    
    self.videoGravityTapChangeGestureRecognizer.tapDelay = 0.3;
    
    BOOL fullScreenButtonHidden = [self shouldHideFullScreenButton];
    [self.fullScreenButtons enumerateObjectsUsingBlock:^(SRGFullScreenButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        button.hidden = fullScreenButtonHidden;
    }];
    
    self.accessibilityView.isAccessibilityElement = YES;
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond;
    });
    
    self.backwardSeekButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ backward", @"Seek backward button label with a custom time range"),
                                                  [s_dateComponentsFormatter stringFromTimeInterval:SRGLetterboxBackwardSkipInterval]];
    self.forwardSeekButton.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"%@ forward", @"Seek forward button label with a custom time range"),
                                                 [s_dateComponentsFormatter stringFromTimeInterval:SRGLetterboxForwardSkipInterval]];
    self.skipToLiveButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Back to live", @"Back to live label");
    
    self.availabilityLabelBackgroundView.layer.cornerRadius = 4.f;
    
    [self reloadData];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateUserInterfaceAnimated:NO];
        [self updateAccessibility];
        [self updateFonts];
        [self reloadData];
        [self registerUserInterfaceUpdateTimers];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wirelessRouteDidChange:)
                                                     name:SRGMediaPlayerWirelessRouteDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenDidConnect:)
                                                     name:UIScreenDidConnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenDidDisconnect:)
                                                     name:UIScreenDidDisconnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serviceSettingsDidChange:)
                                                     name:SRGLetterboxServiceSettingsDidChangeNotification
                                                   object:[SRGLetterboxService sharedService]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChange:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accessibilityVoiceOverStatusChanged:)
                                                     name:UIAccessibilityVoiceOverStatusChanged
                                                   object:nil];
        
        // Automatically resumes in the view when displayed and if picture in picture was active
        if ([SRGLetterboxService sharedService].controller == self.controller) {
            [[SRGLetterboxService sharedService] stopPictureInPictureRestoreUserInterface:NO];
        }
        
        [self showAirplayNotificationMessageIfNeededAnimated:NO];
    }
    else {
        // Invalidate timers
        self.inactivityTimer = nil;
        [self unregisterUserInterfaceUpdateTimers];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIApplicationDidBecomeActiveNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerWirelessRouteDidChangeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidConnectNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenDidDisconnectNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxServiceSettingsDidChangeNotification
                                                      object:[SRGLetterboxService sharedService]];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIContentSizeCategoryDidChangeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIAccessibilityVoiceOverStatusChanged
                                                      object:nil];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL fullScreenButtonHidden = [self shouldHideFullScreenButton];
    [self.fullScreenButtons enumerateObjectsUsingBlock:^(SRGFullScreenButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        button.hidden = fullScreenButtonHidden;
    }];
    
    BOOL isFrameFullScreen = CGRectEqualToRect(self.window.bounds, self.frame);
    self.videoGravityTapChangeGestureRecognizer.enabled = self.fullScreen || isFrameFullScreen;
    
    // The availability component layout depends on the view size. Update appearance
    [self updateAvailabilityForController:self.controller];
}

#pragma mark Fonts

- (void)updateFonts
{
    self.errorLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.errorInstructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.notificationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.timeSlider.timeLeftValueLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    [self updateAvailabilityForController:self.controller];
}

#pragma mark Accessibility

- (void)updateAccessibility
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        self.accessibilityView.alpha = 1.f;
        [self setTogglableUserInterfaceHidden:NO animated:YES];
    }
    else {
        self.accessibilityView.alpha = 0.f;
    }
    
    [self resetInactivityTimer];
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller == controller) {
        return;
    }
    
    if (_controller) {
        SRGMediaPlayerController *previousMediaPlayerController = _controller.mediaPlayerController;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxMetadataDidChangeNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackDidFailNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackDidRetryNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxLivestreamDidFinishNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                      object:previousMediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerSegmentDidStartNotification
                                                      object:previousMediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerSegmentDidEndNotification
                                                      object:previousMediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerWillSkipBlockedSegmentNotification
                                                      object:previousMediaPlayerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGMediaPlayerExternalPlaybackStateDidChangeNotification
                                                      object:previousMediaPlayerController];
        
        [_controller removeObserver:self keyPath:@keypath(_controller.continuousPlaybackUpcomingMedia)];
        
        if (previousMediaPlayerController.view.superview == self.playerView) {
            [previousMediaPlayerController.view removeFromSuperview];
        }
        
        [self updateAvailabilityForController:controller];
    }
    
    _controller = controller;
    
    self.playbackButton.controller = controller;
    self.continuousPlaybackView.controller = controller;
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airplayButton.mediaPlayerController = mediaPlayerController;
    self.tracksButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
    self.viewModeButton.mediaPlayerView = mediaPlayerController.view;
    
    // Notifications are transient and therefore do not need to be persisted at the controller level. They can be simply
    // cleaned up when the controller changes.
    self.notificationMessage = nil;
    
    [self reloadDataForController:controller];
    
    if (controller) {
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        [self registerUserInterfaceUpdateTimersForController:controller];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(metadataDidChange:)
                                                     name:SRGLetterboxMetadataDidChangeNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidFail:)
                                                     name:SRGLetterboxPlaybackDidFailNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidRetry:)
                                                     name:SRGLetterboxPlaybackDidRetryNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(livestreamDidFinish:)
                                                     name:SRGLetterboxLivestreamDidFinishNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGMediaPlayerPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidStart:)
                                                     name:SRGMediaPlayerSegmentDidStartNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidEnd:)
                                                     name:SRGMediaPlayerSegmentDidEndNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willSkipBlockedSegment:)
                                                     name:SRGMediaPlayerWillSkipBlockedSegmentNotification
                                                   object:mediaPlayerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(externalPlaybackStateDidChange:)
                                                     name:SRGMediaPlayerExternalPlaybackStateDidChangeNotification
                                                   object:mediaPlayerController];
        
        @weakify(self)
        @weakify(controller)
        [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            @strongify(controller)
            [self updateUserInterfaceForController:controller animated:YES];
        }];
        
        [self.playerView addSubview:mediaPlayerController.view];
        
        // Force autolayout to ensure the layout is immediately correct 
        [mediaPlayerController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playerView);
        }];
        
        [self.playerView layoutIfNeeded];
    }
    else {
        [self unregisterUserInterfaceUpdateTimers];
    }
    
    [self updateUserInterfaceForController:controller animated:NO];
    [self updateTimeLabelsForController:controller];
}

- (void)setDelegate:(id<SRGLetterboxViewDelegate>)delegate
{
    _delegate = delegate;
    
    BOOL fullScreenButtonHidden = [self shouldHideFullScreenButton];
    [self.fullScreenButtons enumerateObjectsUsingBlock:^(SRGFullScreenButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        button.hidden = fullScreenButtonHidden;
    }];
}

- (void)setUserInterfaceUpdateTimer:(NSTimer *)userInterfaceUpdateTimer
{
    [_userInterfaceUpdateTimer invalidate];
    _userInterfaceUpdateTimer = userInterfaceUpdateTimer;
}

- (void)setFullScreen:(BOOL)fullScreen
{
    [self setFullScreen:fullScreen animated:NO];
}

- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated
{
    if (! [self.delegate respondsToSelector:@selector(letterboxView:toggleFullScreen:animated:withCompletionHandler:)]) {
        return;
    }
    
    if (_fullScreen == fullScreen) {
        return;
    }
    
    if (self.fullScreenAnimationRunning) {
        SRGLetterboxLogInfo(@"view", @"A full screen animation is already running");
        return;
    }
    
    self.fullScreenAnimationRunning = YES;
    
    [self.delegate letterboxView:self toggleFullScreen:fullScreen animated:animated withCompletionHandler:^(BOOL finished) {
        if (finished) {
            BOOL fullScreenButtonHidden = [self shouldHideFullScreenButton];
            [self.fullScreenButtons enumerateObjectsUsingBlock:^(SRGFullScreenButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
                button.selected = fullScreen;
                button.hidden = fullScreenButtonHidden;
            }];
            
            _fullScreen = fullScreen;
            
            BOOL isFrameFullScreen = self.window && CGRectEqualToRect(self.window.bounds, self.frame);
            self.videoGravityTapChangeGestureRecognizer.enabled = self.fullScreen || isFrameFullScreen;
            [self updateUserInterfaceAnimated:animated];
        }
        self.fullScreenAnimationRunning = NO;
    }];
}

- (void)setInactivityTimer:(NSTimer *)inactivityTimer
{
    [_inactivityTimer invalidate];
    _inactivityTimer = inactivityTimer;
}

- (NSError *)errorForController:(SRGLetterboxController *)controller
{
    NSError *error = controller.error;
    if (error) {
        // Do not display unavailability controller errors as errors within the view (pre- and post-roll UI will be
        // displayed instead)
        if ([error.domain isEqualToString:SRGLetterboxErrorDomain] && error.code == SRGLetterboxErrorCodeNotAvailable) {
            return nil;
        }
        else {
            return error;
        }
    }
    else {
        return nil;
    }
}

- (BOOL)isAvailabilityViewHiddenForController:(SRGLetterboxController *)controller
{
    SRGBlockingReason blockingReason = [controller.media blockingReasonAtDate:[NSDate date]];
    return ! controller.media || (blockingReason != SRGBlockingReasonStartDate && blockingReason != SRGBlockingReasonEndDate);
}

- (SRGLetterboxViewBehavior)userInterfaceBehavior
{
    return [self userInterfaceBehaviorForController:self.controller];
}

- (SRGLetterboxViewBehavior)userInterfaceBehaviorForController:(SRGLetterboxController *)controller
{
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
    
    // Controls and error overlays must never be displayed at the same time. This does not change the final expected
    // control visbility state variable, only its visual result.
    BOOL hasError = ([self errorForController:controller] != nil);
    BOOL hasMedia = controller.media || controller.URN;
    BOOL isAvailabilityViewVisible = ! [self isAvailabilityViewHiddenForController:controller];
    BOOL isUsingAirplay = [AVAudioSession srg_isAirplayActive] && (controller.media.mediaType == SRGMediaTypeAudio || mediaPlayerController.player.externalPlaybackActive);
    
    if (hasError || ! hasMedia || isAvailabilityViewVisible || controller.dataAvailability == SRGLetterboxDataAvailabilityLoading) {
        return SRGLetterboxViewBehaviorForcedHidden;
    }
    else if (self.userInterfaceTogglable
             && (playbackState == SRGMediaPlayerPlaybackStateIdle || playbackState == SRGMediaPlayerPlaybackStateEnded || isUsingAirplay || controller.dataAvailability == SRGLetterboxDataAvailabilityNone)) {
        return SRGLetterboxViewBehaviorForcedVisible;
    }
    else {
        return SRGLetterboxViewBehaviorNormal;
    }
}

- (SRGLetterboxViewBehavior)timelineBehaviorForController:(SRGLetterboxController *)controller
{
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
    
    // Timeline and error overlays must be displayed at the same time.
    BOOL hasError = ([self errorForController:controller] != nil);
    BOOL isAvailabilityViewVisible = ! [self isAvailabilityViewHiddenForController:controller];
    BOOL isUsingAirplay = [AVAudioSession srg_isAirplayActive] && (controller.media.mediaType == SRGMediaTypeAudio || mediaPlayerController.player.externalPlaybackActive);
    
    if (! [self isTimelineAlwaysHidden]
        && (hasError || isAvailabilityViewVisible || isUsingAirplay || (controller.dataAvailability == SRGLetterboxDataAvailabilityLoaded && playbackState == SRGMediaPlayerPlaybackStateIdle)
                || playbackState == SRGMediaPlayerPlaybackStateEnded)) {
            return SRGLetterboxViewBehaviorForcedVisible;
        }
    else {
        return SRGLetterboxViewBehaviorNormal;
    }
}

- (void)setPreferredTimelineHeight:(CGFloat)preferredTimelineHeight animated:(BOOL)animated
{
    if (preferredTimelineHeight < 0.f) {
        SRGLetterboxLogWarning(@"view", @"The preferred timeline height must be >= 0. Fixed to 0");
        preferredTimelineHeight = 0.f;
    }
    
    if (self.preferredTimelineHeight == preferredTimelineHeight) {
        return;
    }
    
    self.preferredTimelineHeight = preferredTimelineHeight;
    [self updateUserInterfaceAnimated:animated];
}

- (BOOL)isTimelineAlwaysHidden
{
    return self.preferredTimelineHeight == 0;
}

- (void)setTimelineAlwaysHidden:(BOOL)timelineAlwaysHidden animated:(BOOL)animated
{
    [self setPreferredTimelineHeight:(timelineAlwaysHidden ? 0.f : SRGLetterboxViewDefaultTimelineHeight) animated:animated];
}

- (CGFloat)timelineHeight
{
    return self.timelineHeightConstraint.constant;
}

- (NSArray<SRGSubdivision *> *)subdivisions
{
    return self.timelineView.subdivisions;
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

#pragma mark Data display

- (void)setNeedsSubdivisionFavoritesUpdate
{
    [self.timelineView setNeedsSubdivisionFavoritesUpdate];
}

- (NSArray<SRGSubdivision *> *)subdivisionsForMediaComposition:(SRGMediaComposition *)mediaComposition
{
    if (! mediaComposition) {
        return nil;
    }
    
    // Show visible segments for the current chapter (if any), and display other chapters but not expanded. If
    // there is only a chapter, do not display it
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NO", @keypath(SRGSubdivision.new, hidden)];
    NSArray<SRGChapter *> *visibleChapters = [mediaComposition.chapters filteredArrayUsingPredicate:predicate];
 
    NSMutableArray<SRGSubdivision *> *subdivisions = [NSMutableArray array];
    for (SRGChapter *chapter in visibleChapters) {
        if (chapter == mediaComposition.mainChapter && chapter.segments.count != 0) {
            NSArray<SRGSegment *> *visibleSegments = [chapter.segments filteredArrayUsingPredicate:predicate];
            [subdivisions addObjectsFromArray:visibleSegments];
        }
        else if (visibleChapters.count > 1) {
            [subdivisions addObject:chapter];
        }
    }
    return [subdivisions copy];
}

// Responsible of updating the data to be displayed. Must not alter visibility of UI elements or anything else
- (void)reloadDataForController:(SRGLetterboxController *)controller
{
    SRGMediaComposition *mediaComposition = controller.mediaComposition;
    SRGSubdivision *subdivision = (SRGSegment *)controller.mediaPlayerController.currentSegment ?: mediaComposition.mainSegment ?: mediaComposition.mainChapter;
    
    self.timelineView.chapterURN = mediaComposition.mainChapter.URN;
    self.timelineView.subdivisions = [self subdivisionsForMediaComposition:mediaComposition];
    self.timelineView.selectedIndex = subdivision ? [self.timelineView.subdivisions indexOfObject:subdivision] : NSNotFound;
    
    [self reloadImageForController:controller];
    
    NSError *error = [self errorForController:controller];
    
    UIImage *image = [UIImage srg_letterboxImageForError:error];
    self.errorImageView.image = image;
    self.errorImageView.hidden = (image == nil);            // Hidden so that the stack view wrapper can adjust its layout properly
    
    self.errorLabel.text = error.localizedDescription;
    
    [self updateAvailabilityForController:controller];
}

- (void)updateAvailabilityForController:(SRGLetterboxController *)controller
{
    SRGMedia *media = controller.media;
    self.availabilityLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:[NSDate date]];
    if (blockingReason == SRGBlockingReasonEndDate) {
        self.availabilityLabel.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"Expired", @"Label to explain that a content has expired")];
        self.availabilityLabel.hidden = NO;
        self.availabilityLabelBackgroundView.hidden = NO;
        
        self.countdownView.hidden = YES;
    }
    else if (blockingReason == SRGBlockingReasonStartDate) {
        NSTimeInterval timeIntervalBeforeStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(timeIntervalBeforeStart);
        
        // Large number of days. Label only
        if (dateComponents.day >= SRGCountdownViewDaysLimit) {
            static NSDateComponentsFormatter *s_dateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
                s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
            });
            
            self.availabilityLabel.text = [NSString stringWithFormat:@"  %@  ", [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_dateComponentsFormatter stringFromTimeInterval:timeIntervalBeforeStart]]];
            self.availabilityLabel.hidden = NO;
            self.availabilityLabelBackgroundView.hidden = NO;
            
            self.countdownView.hidden = YES;
        }
        // Tiny layout
        else if (CGRectGetWidth(self.frame) < 290.f) {
            NSString *availabilityLabelText = nil;
            if (dateComponents.day > 0) {
                availabilityLabelText = [[NSDateComponentsFormatter srg_longDateComponentsFormatter] stringFromDateComponents:dateComponents];
            }
            else if (timeIntervalBeforeStart >= 60. * 60.) {
                availabilityLabelText = [[NSDateComponentsFormatter srg_mediumDateComponentsFormatter] stringFromDateComponents:dateComponents];
            }
            else if (timeIntervalBeforeStart >= 0) {
                availabilityLabelText = [[NSDateComponentsFormatter srg_shortDateComponentsFormatter] stringFromDateComponents:dateComponents];
            }
            else {
                availabilityLabelText = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
            }
            
            self.availabilityLabel.hidden = NO;
            self.availabilityLabel.text = [NSString stringWithFormat:@"  %@  ", availabilityLabelText];
            self.availabilityLabelBackgroundView.hidden = NO;
            
            self.countdownView.hidden = YES;
        }
        // Large layout
        else {
            self.availabilityLabel.hidden = YES;
            self.availabilityLabelBackgroundView.hidden = YES;
            
            self.countdownView.remainingTimeInterval = timeIntervalBeforeStart;
            self.countdownView.hidden = NO;
        }
    }
    else {
        self.availabilityLabel.hidden = YES;
        self.availabilityLabelBackgroundView.hidden = YES;
        
        self.countdownView.hidden = YES;
    }
}

- (void)reloadImageForController:(SRGLetterboxController *)controller
{
    // For livestreams, rely on channel information when available
    SRGMedia *media = controller.subdivisionMedia ?: controller.media;
    if (media.contentType == SRGContentTypeLivestream && controller.channel) {
        SRGChannel *channel = controller.channel;
        
        // Display program artwork (if any) when the slider position is within the current program, otherwise channel artwork.
        NSDate *sliderDate = self.timeSlider.date;
        if (sliderDate && [channel.currentProgram srgletterbox_containsDate:sliderDate]) {
            [self.imageView srg_requestImageForObject:channel.currentProgram withScale:SRGImageScaleLarge type:SRGImageTypeDefault unavailabilityHandler:^{
                [self.imageView srg_requestImageForObject:channel withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
            }];
        }
        else {
            [self.imageView srg_requestImageForObject:channel withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
        }
    }
    else {
        [self.imageView srg_requestImageForObject:media withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
    }
}

- (void)reloadData
{
    return [self reloadDataForController:self.controller];
}

#pragma mark UI behavior changes

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable
{
    self.userInterfaceHidden = hidden;
    self.userInterfaceTogglable = togglable;
    
    [self updateUserInterfaceAnimated:animated];
}

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self setUserInterfaceHidden:hidden animated:animated togglable:self.userInterfaceTogglable];
}

// Only alter user interface visibility if togglable
- (void)setTogglableUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (! self.userInterfaceTogglable) {
        return;
    }
    
    [self setUserInterfaceHidden:hidden animated:animated togglable:self.userInterfaceTogglable];
}

#pragma mark UI updates

- (BOOL)updateLayoutForController:(SRGLetterboxController *)controller
{
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
    
    BOOL userInterfaceHidden = NO;
    switch ([self userInterfaceBehaviorForController:controller]) {
        case SRGLetterboxViewBehaviorForcedHidden: {
            userInterfaceHidden = YES;
            break;
        }
            
        case SRGLetterboxViewBehaviorForcedVisible: {
            userInterfaceHidden = NO;
            break;
        }
            
        default: {
            userInterfaceHidden = self.userInterfaceHidden;
            break;
        }
    }
    
    static const CGFloat kControlsStackConstraintGreaterPriority = 950.f;
    static const CGFloat kControlsStackConstraintLesserPriority = 850.f;
    
    if (userInterfaceHidden) {
        [self.controlsStackToSafeAreaEdgeConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
            constraint.priority = kControlsStackConstraintLesserPriority;
        }];
        [self.controlsStackToSuperviewEdgeConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
            constraint.priority = kControlsStackConstraintGreaterPriority;
        }];
    }
    else {
        [self.controlsStackToSafeAreaEdgeConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
            constraint.priority = kControlsStackConstraintGreaterPriority;
        }];
        [self.controlsStackToSuperviewEdgeConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
            constraint.priority = kControlsStackConstraintLesserPriority;
        }];
    }
    
    self.notificationImageView.hidden = (self.notificationMessage == nil);
    self.notificationLabelBottomConstraint.constant = (self.notificationMessage != nil) ? 6.f : 0.f;
    self.notificationLabelTopConstraint.constant = (self.notificationMessage != nil) ? 6.f : 0.f;

    BOOL hasError = ([self errorForController:controller] != nil);
    BOOL hasMedia = controller.media || controller.URN;
    BOOL isContinuousPlaybackViewVisible = (controller.continuousPlaybackUpcomingMedia != nil);
    BOOL isAvailabilityViewVisible = ! [self isAvailabilityViewHiddenForController:controller] && ! isContinuousPlaybackViewVisible;
    
    self.controlsView.alpha = (! userInterfaceHidden && ! isContinuousPlaybackViewVisible) ? 1.f : 0.f;
    
    self.errorView.hidden = (! hasError && hasMedia) || isAvailabilityViewVisible || isContinuousPlaybackViewVisible;
    self.errorInstructionsLabel.text = controller.URN ? SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry") : nil;
    
    self.availabilityView.alpha = isAvailabilityViewVisible ? 1.f : 0.f;
    self.continuousPlaybackWrapperView.alpha = isContinuousPlaybackViewVisible ? 1.f : 0.f;
    
    // Hide video view if a video is played with AirPlay or if "true screen mirroring" is used (device screen copy with no full-screen
    // playback on the external device)
    SRGMedia *media = controller.media;
    BOOL playerViewVisible = (media.mediaType == SRGMediaTypeVideo && ! mediaPlayerController.externalNonMirroredPlaybackActive
                              && playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStatePreparing && playbackState != SRGMediaPlayerPlaybackStateEnded);
    if (@available(iOS 11, *)) {
        if ([NSBundle srg_letterbox_isProductionVersion] && [UIScreen mainScreen].captured && ! [AVAudioSession srg_isAirplayActive]) {
            playerViewVisible = NO;
        }
    }
    
    self.imageView.alpha = playerViewVisible ? 0.f : 1.f;
    mediaPlayerController.view.alpha = playerViewVisible ? 1.f : 0.f;
    
    return userInterfaceHidden;
}

- (CGFloat)updateTimelineLayoutForController:(SRGLetterboxController *)controller userInterfaceHidden:(BOOL)userInterfaceHidden
{
    NSArray<SRGSubdivision *> *subdivisions = [self subdivisionsForMediaComposition:controller.mediaComposition];
    SRGLetterboxViewBehavior timelineBehavior = [self timelineBehaviorForController:controller];
    CGFloat timelineHeight = (subdivisions.count != 0 && ! controller.continuousPlaybackTransitionEndDate && ((timelineBehavior == SRGLetterboxViewBehaviorNormal && ! userInterfaceHidden) || timelineBehavior == SRGLetterboxViewBehaviorForcedVisible)) ? self.preferredTimelineHeight : 0.f;
    
    // Scroll to selected index when opening the timeline
    BOOL isTimelineVisible = (timelineHeight != 0.f);
    BOOL shouldFocus = (self.timelineHeightConstraint.constant == 0.f && isTimelineVisible);
    self.timelineHeightConstraint.constant = timelineHeight;
    
    if (shouldFocus) {
        [self.timelineView scrollToSelectedIndexAnimated:NO];
    }
    
    // Ensure the timeline is always contained within the safe area when displayed
    static const CGFloat kTimelineConstraintGreaterPriority = 950.f;
    static const CGFloat kTimelineConstraintLesserPriority = 850.f;
    
    if (isTimelineVisible) {
        self.timelineToSafeAreaBottomConstraint.priority = kTimelineConstraintGreaterPriority;
        self.timelineToSuperviewBottomConstraint.priority = kTimelineConstraintLesserPriority;
    }
    else {
        self.timelineToSafeAreaBottomConstraint.priority = kTimelineConstraintLesserPriority;
        self.timelineToSuperviewBottomConstraint.priority = kTimelineConstraintGreaterPriority;
    }
    
    return timelineHeight;
}

- (CGFloat)updateNotificationLayout
{
    // The notification message determines the height of the view required to display it.
    self.notificationLabel.text = self.notificationMessage;
    
    // Force autolayout
    [self.notificationView setNeedsLayout];
    [self.notificationView layoutIfNeeded];
    
    // Return the minimum size which satisfies the constraints. Put a strong requirement on width and properly let the height
    // adjusts
    // For an explanation, see http://titus.io/2015/01/13/a-better-way-to-autosize-in-ios-8.html
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.width = CGRectGetWidth(self.notificationView.frame);
    return [self.notificationView systemLayoutSizeFittingSize:fittingSize
                                withHorizontalFittingPriority:UILayoutPriorityRequired
                                      verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
}

- (void)updateControlsLayoutForController:(SRGLetterboxController *)controller
{
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    // General playback controls
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        self.forwardSeekButton.alpha = 0.f;
        self.backwardSeekButton.alpha = 0.f;
        self.skipToLiveButton.alpha = [controller canSkipToLive] ? 1.f : 0.f;
        
        self.timeSlider.alpha = 0.f;
        self.timeSlider.timeLeftValueLabel.hidden = YES;
    }
    else {
        self.forwardSeekButton.alpha = [controller canSkipForward] ? 1.f : 0.f;
        self.backwardSeekButton.alpha = [controller canSkipBackward] ? 1.f : 0.f;
        self.skipToLiveButton.alpha = [controller canSkipToLive] ? 1.f : 0.f;
        
        switch (mediaPlayerController.streamType) {
            case SRGMediaPlayerStreamTypeOnDemand: {
                self.timeSlider.alpha = 1.f;
                self.timeSlider.timeLeftValueLabel.hidden = NO;
                break;
            }
                
            case SRGMediaPlayerStreamTypeLive: {
                self.timeSlider.alpha = 0.f;
                self.timeSlider.timeLeftValueLabel.hidden = NO;
                break;
            }
                
            case SRGMediaPlayerStreamTypeDVR: {
                self.timeSlider.alpha = 1.f;
                // Hide timeLeftValueLabel to give the width space to the timeSlider
                self.timeSlider.timeLeftValueLabel.hidden = YES;
                break;
            }
                
            default: {
                self.timeSlider.alpha = 0.f;
                self.timeSlider.timeLeftValueLabel.hidden = YES;
                break;
            }
        }
    }
    
    // Play button / loading indicator visibility
    BOOL isPlayerLoading = mediaPlayerController && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePlaying
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePaused
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle;
    
    BOOL visible = isPlayerLoading || controller.dataAvailability == SRGLetterboxDataAvailabilityLoading;
    if (visible) {
        self.playbackButton.alpha = 0.f;
        
        self.loadingImageView.alpha = 1.f;
        [self.loadingImageView startAnimating];
    }
    else {
        self.playbackButton.alpha = 1.f;
        
        self.loadingImageView.alpha = 0.f;
        [self.loadingImageView stopAnimating];
    }
}

- (void)updateUserInterfaceForController:(SRGLetterboxController *)controller animated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(letterboxViewWillAnimateUserInterface:)]) {
        _inWillAnimateUserInterface = YES;
        [self.delegate letterboxViewWillAnimateUserInterface:self];
        _inWillAnimateUserInterface = NO;
    }
    
    void (^animations)(void) = ^{
        BOOL userInterfaceHidden = [self updateLayoutForController:controller];
        CGFloat timelineHeight = [self updateTimelineLayoutForController:controller userInterfaceHidden:userInterfaceHidden];
        CGFloat notificationHeight = [self updateNotificationLayout];
        [self updateControlsLayoutForController:controller];
        
        self.animations ? self.animations(userInterfaceHidden, timelineHeight + notificationHeight) : nil;
        
        BOOL isFrameFullScreen = self.window && CGRectEqualToRect(self.window.bounds, self.frame);
        if (! self.fullScreen && ! isFrameFullScreen) {
            self.targetVideoGravity = AVLayerVideoGravityResizeAspect;
        }
        
        AVPlayerLayer *playerLayer = controller.mediaPlayerController.playerLayer;
        if (self.targetVideoGravity) {
            playerLayer.videoGravity = self.targetVideoGravity;
            self.targetVideoGravity = nil;
        }
        
        static const CGFloat kControlsFillLesserPriority = 850.f;
        static const CGFloat kControlsFillGreaterPriority = 950.f;
        
        if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
            [self.controlsToSuperviewEdgeConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
                constraint.priority = kControlsFillLesserPriority;
            }];
        }
        else {
            [self.controlsToSuperviewEdgeConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
                constraint.priority = kControlsFillGreaterPriority;
            }];
        }
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.completion ? self.completion(finished) : nil;
        
        self.animations = nil;
        self.completion = nil;
    };
    
    if (animated) {
        [self layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self layoutIfNeeded];
        } completion:completion];
    }
    else {
        animations();
        completion(YES);
    }
}

- (void)updateTimeLabels
{
    [self updateTimeLabelsForController:self.controller];
}

- (void)updateTimeLabelsForController:(SRGLetterboxController *)controller
{
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    if (playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStateEnded && playbackState != SRGMediaPlayerPlaybackStatePreparing
            && self.controller.mediaPlayerController.streamType == SRGStreamTypeOnDemand) {
        SRGChapter *mainChapter = self.controller.mediaComposition.mainChapter;
        
        NSTimeInterval durationInSeconds = mainChapter.duration / 1000;
        if (durationInSeconds < 60. * 60) {
            self.durationLabel.text = [[NSDateComponentsFormatter srg_shortDateComponentsFormatter] stringFromTimeInterval:durationInSeconds];
        }
        else {
            self.durationLabel.text = [[NSDateComponentsFormatter srg_mediumDateComponentsFormatter] stringFromTimeInterval:durationInSeconds];
        }
    }
    else {
        self.durationLabel.text = nil;
    }
}

- (void)updateUserInterfaceAnimated:(BOOL)animated
{
    [self updateUserInterfaceForController:self.controller animated:animated];
}

- (void)registerUserInterfaceUpdateTimersForController:(SRGLetterboxController *)controller
{
    @weakify(self)
    @weakify(controller)
    self.userInterfaceUpdateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
        @strongify(self)
        @strongify(controller)
        [self updateUserInterfaceForController:controller animated:YES];
        [self updateAvailabilityForController:controller];
        [self updateTimeLabelsForController:controller];
    }];
}

- (void)registerUserInterfaceUpdateTimers
{
    return [self registerUserInterfaceUpdateTimersForController:self.controller];
}

- (void)unregisterUserInterfaceUpdateTimers
{
    self.userInterfaceUpdateTimer = nil;
}

- (void)resetInactivityTimer
{
    if (! UIAccessibilityIsVoiceOverRunning()) {
        @weakify(self)
        self.inactivityTimer = [NSTimer srg_scheduledTimerWithTimeInterval:4. repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            
            // Only auto-hide the UI when it makes sense (e.g. not when the player is paused or loading). When the state
            // of the player returns to playing, the inactivity timer will be reset (see -playbackStateDidChange:)
            SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
            if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
                    || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking
                    || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateStalled) {
                [self setTogglableUserInterfaceHidden:YES animated:YES];
            }
        }];
    }
    else {
        self.inactivityTimer = nil;
    }
}

- (void)animateAlongsideUserInterfaceWithAnimations:(void (^)(BOOL, CGFloat))animations completion:(void (^)(BOOL finished))completion
{
    if (! _inWillAnimateUserInterface) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"-animateAlongsideUserInterfaceWithAnimations:completion: can only be called from within the -animateAlongsideUserInterfaceWithAnimations: method of the Letterbox view delegate"
                                     userInfo:nil];
    }
    
    self.animations = animations;
    self.completion = completion;
}

- (BOOL)shouldHideFullScreenButton
{
    if (! [self.delegate respondsToSelector:@selector(letterboxView:toggleFullScreen:animated:withCompletionHandler:)]) {
        return YES;
    }
    
    if (! [self.delegate respondsToSelector:@selector(letterboxViewShouldDisplayFullScreenToggleButton:)]) {
        return NO;
    }
    
    return ! [self.delegate letterboxViewShouldDisplayFullScreenToggleButton:self];
}

- (void)showAirplayNotificationMessageIfNeededAnimated:(BOOL)animated
{
    if (self.controller.mediaPlayerController.externalNonMirroredPlaybackActive) {
        [self showNotificationMessage:SRGLetterboxLocalizedString(@"Playback on AirPlay", @"Message displayed when broadcasting on an AirPlay device") animated:animated];
    }
}

#pragma mark Letterbox notification banners

- (void)showNotificationMessage:(NSString *)notificationMessage animated:(BOOL)animated
{
    if (notificationMessage.length == 0) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissNotificationView) object:nil];
    
    self.notificationMessage = notificationMessage;
    
    [self updateUserInterfaceAnimated:animated];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, notificationMessage);
    
    [self performSelector:@selector(dismissNotificationView) withObject:nil afterDelay:5.];
}

- (void)dismissNotificationView
{
    [self dismissNotificationViewAnimated:YES];
}

- (void)dismissNotificationViewAnimated:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    self.notificationMessage = nil;
    [self updateUserInterfaceAnimated:animated];
}

#pragma mark Subdivisions

// Return the subdivision in the timeline at the specified time
- (SRGSubdivision *)subdivisionOnTimelineAtTime:(CMTime)time
{
    SRGChapter *mainChapter = self.controller.mediaComposition.mainChapter;
    SRGSubdivision *subdivision = mainChapter;
    
    // For chapters without segments, return the chapter, otherwise the segment at time
    if (mainChapter.segments.count != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGSegment *  _Nullable segment, NSDictionary<NSString *,id> * _Nullable bindings) {
            return CMTimeRangeContainsTime(segment.srg_timeRange, time);
        }];
        subdivision = [mainChapter.segments filteredArrayUsingPredicate:predicate].firstObject;
    }
    return [self.timelineView.subdivisions containsObject:subdivision] ? subdivision : nil;
}

#pragma mark Gesture recognizers

- (void)resetInactivityTimer:(UIGestureRecognizer *)gestureRecognizer
{
    [self resetInactivityTimer];
}

- (IBAction)showUserInterface:(UIGestureRecognizer *)gestureRecognizer
{
    [self setTogglableUserInterfaceHidden:NO animated:YES];
}

- (IBAction)hideUserInterface:(UIGestureRecognizer *)gestureRecognizer
{
    // Defer execution to avoid conflicts with the activity gesture above
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setTogglableUserInterfaceHidden:YES animated:YES];
    });
}

- (IBAction)changeVideoGravity:(UIGestureRecognizer *)gestureRecognizer
{
    AVPlayerLayer *playerLayer = self.controller.mediaPlayerController.playerLayer;
    
    // Set the desired content gravity, based on the current layer state. The result is applied with UI updates,
    // ensuring all updates are animated at the same time.
    if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        self.targetVideoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    else {
        self.targetVideoGravity = AVLayerVideoGravityResizeAspect;
    }
    
    [self updateUserInterfaceAnimated:YES];
}

#pragma mark Actions

- (IBAction)skipBackward:(id)sender
{
    [self.controller skipBackwardWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToPlaybackTime:self.timeSlider.time withValue:self.timeSlider.value interactive:YES];
    }];
}

- (IBAction)skipForward:(id)sender
{
    [self.controller skipForwardWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToPlaybackTime:self.timeSlider.time withValue:self.timeSlider.value interactive:YES];
    }];
}

- (IBAction)toggleFullScreen:(id)sender
{
    [self setFullScreen:!self.isFullScreen animated:YES];
}

- (IBAction)skipToLive:(id)sender
{
    [self.controller skipToLiveWithCompletionHandler:nil];
}

- (IBAction)retry:(id)sender
{
    [self.controller restart];
}

#pragma mark SRGContinuousPlaybackViewDelegate protocol

- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didEngageWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    if ([self.delegate respondsToSelector:@selector(letterboxView:didEngageInContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxView:self didEngageInContinuousPlaybackWithUpcomingMedia:upcomingMedia];
    }
}

- (void)continuousPlaybackView:(SRGContinuousPlaybackView *)continuousPlaybackView didCancelWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    if ([self.delegate respondsToSelector:@selector(letterboxView:didCancelContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxView:self didCancelContinuousPlaybackWithUpcomingMedia:upcomingMedia];
    }
}

#pragma mark SRGControlsViewDelegate protocol

- (void)controlsViewDidLayoutSubviews:(SRGControlsView *)controlsView
{
    SRGImageSet imageSet = (CGRectGetWidth(self.playerView.bounds) < 668.f) ? SRGImageSetNormal : SRGImageSetLarge;
    CGFloat horizontalSpacing = (imageSet == SRGImageSetNormal) ? 0.f : 20.f;
    
    self.horizontalSpacingPlaybackToBackwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingPlaybackToForwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingForwardToSkipToLiveConstraint.constant = horizontalSpacing;
    
    self.playbackButton.imageSet = imageSet;
    
    [self.backwardSeekButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSeekButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.skipToLiveButton setImage:[UIImage srg_letterboxSkipToLiveImageInSet:imageSet] forState:UIControlStateNormal];
}

#pragma mark SRGLetterboxTimelineViewDelegate protocol

- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didSelectSubdivision:(SRGSubdivision *)subdivision
{
    if (! [self.controller switchToSubdivision:subdivision withCompletionHandler:nil]) {
        return;
    }
    
    if ([subdivision isKindOfClass:[SRGSegment class]]) {
        SRGSegment *segment = (SRGSegment *)subdivision;
        self.timelineView.time = CMTimeMakeWithSeconds(segment.markIn / 1000., NSEC_PER_SEC);
    }
    else {
        self.timelineView.chapterURN = subdivision.URN;
        self.timelineView.time = kCMTimeZero;
    }
    self.timelineView.selectedIndex = [timelineView.subdivisions indexOfObject:subdivision];
    [self.timelineView scrollToSelectedIndexAnimated:YES];
    
    if ([self.delegate respondsToSelector:@selector(letterboxView:didSelectSubdivision:)]) {
        [self.delegate letterboxView:self didSelectSubdivision:subdivision];
    }
}

- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didLongPressSubdivision:(SRGSubdivision *)subdivision
{
    if ([self.delegate respondsToSelector:@selector(letterboxView:didLongPressSubdivision:)]) {
        [self.delegate letterboxView:self didLongPressSubdivision:subdivision];
    }
}

- (BOOL)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView shouldDisplayFavoriteForSubdivision:(SRGSubdivision *)subdivision
{
    if ([self.delegate respondsToSelector:@selector(letterboxView:shouldDisplayFavoriteForSubdivision:)]) {
        return [self.delegate letterboxView:self shouldDisplayFavoriteForSubdivision:subdivision];
    }
    else {
        return NO;
    }
}

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToPlaybackTime:(CMTime)time withValue:(CGFloat)value interactive:(BOOL)interactive
{
    SRGSubdivision *selectedSubdivision = [self subdivisionOnTimelineAtTime:time];
    
    if (interactive) {
        NSInteger selectedIndex = [self.timelineView.subdivisions indexOfObject:selectedSubdivision];
        self.timelineView.selectedIndex = selectedIndex;
        [self.timelineView scrollToSelectedIndexAnimated:YES];
    }
    self.timelineView.time = time;
    
    if ([self.delegate respondsToSelector:@selector(letterboxView:didScrollWithSubdivision:time:interactive:)]) {
        [self.delegate letterboxView:self didScrollWithSubdivision:selectedSubdivision time:time interactive:interactive];
    }
    
    [self reloadImageForController:self.controller];
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.videoGravityTapChangeGestureRecognizer) {
        return [otherGestureRecognizer isKindOfClass:[SRGActivityGestureRecognizer class]] || otherGestureRecognizer == self.showUserInterfaceTapGestureRecognizer;
    }
    else {
        return NO;
    }
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self reloadData];
    [self updateUserInterfaceAnimated:YES];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    self.timelineView.selectedIndex = NSNotFound;
    self.timelineView.time = kCMTimeZero;
    
    [self reloadData];
    [self updateUserInterfaceAnimated:YES];
}

- (void)playbackDidRetry:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
}

- (void)livestreamDidFinish:(NSNotification *)notification
{
    [self showNotificationMessage:SRGLetterboxLocalizedString(@"Live broadcast ended", @"Notification message displayed when a live broadcast has finished.") animated:YES];
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
    [self updateTimeLabels];
    
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    SRGMediaPlayerPlaybackState previousPlaybackState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
    if (playbackState == SRGMediaPlayerPlaybackStatePlaying && previousPlaybackState == SRGMediaPlayerPlaybackStatePreparing) {
        [self.timelineView scrollToSelectedIndexAnimated:YES];
        [self showAirplayNotificationMessageIfNeededAnimated:YES];
    }
    else if (playbackState == SRGMediaPlayerPlaybackStatePaused && previousPlaybackState == SRGMediaPlayerPlaybackStatePreparing) {
        [self showAirplayNotificationMessageIfNeededAnimated:YES];
    }
    else if (playbackState == SRGMediaPlayerPlaybackStateSeeking) {
        if (notification.userInfo[SRGMediaPlayerSeekTimeKey]) {
            CMTime seekTargetTime = [notification.userInfo[SRGMediaPlayerSeekTimeKey] CMTimeValue];
            SRGSubdivision *subdivision = [self subdivisionOnTimelineAtTime:seekTargetTime];
            self.timelineView.selectedIndex = [self.timelineView.subdivisions indexOfObject:subdivision];
            self.timelineView.time = seekTargetTime;
        }
    }
}

- (void)segmentDidStart:(NSNotification *)notification
{
    SRGSubdivision *subdivision = notification.userInfo[SRGMediaPlayerSegmentKey];
    self.timelineView.selectedIndex = [self.timelineView.subdivisions indexOfObject:subdivision];
    [self.timelineView scrollToSelectedIndexAnimated:YES];
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    self.timelineView.selectedIndex = NSNotFound;
}

- (void)willSkipBlockedSegment:(NSNotification *)notification
{
    SRGSubdivision *subdivision = notification.userInfo[SRGMediaPlayerSegmentKey];
    NSString *notificationMessage = SRGMessageForSkippedSegmentWithBlockingReason([subdivision blockingReasonAtDate:[NSDate date]]);
    [self showNotificationMessage:notificationMessage animated:YES];
}

- (void)externalPlaybackStateDidChange:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
    [self showAirplayNotificationMessageIfNeededAnimated:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
}

// Called when the route is changed from the control center
- (void)wirelessRouteDidChange:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
    [self showAirplayNotificationMessageIfNeededAnimated:YES];
}

- (void)screenDidConnect:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
}

- (void)screenDidDisconnect:(NSNotification *)notification
{
    [self updateUserInterfaceAnimated:YES];
}

- (void)serviceSettingsDidChange:(NSNotification *)notification
{
    [self reloadData];
    [self updateUserInterfaceAnimated:YES];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self updateAccessibility];
}

@end

static void commonInit(SRGLetterboxView *self)
{
    // This makes design in a xib and Interface Builder preview (IB_DESIGNABLE) work. The top-level view must NOT be
    // an SRGLetterboxView to avoid infinite recursion
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.userInterfaceHidden = NO;
    self.userInterfaceTogglable = YES;
    
    self.videoGravityTapChangeGestureRecognizer.enabled = NO;
    
    self.continuousPlaybackView.delegate = self;
    
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        self.accessibilityIgnoresInvertColors = YES;
    }
#endif
    
    self.preferredTimelineHeight = SRGLetterboxViewDefaultTimelineHeight;
}
