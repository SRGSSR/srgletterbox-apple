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
#import "SRGAvailabilityView.h"
#import "SRGContinuousPlaybackView.h"
#import "SRGControlsView.h"
#import "SRGCountdownView.h"
#import "SRGErrorView.h"
#import "SRGFullScreenButton.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxLogger.h"
#import "SRGLetterboxPlaybackButton.h"
#import "SRGLetterboxService+Private.h"
#import "SRGLetterboxTimelineView.h"
#import "SRGLetterboxTimeSlider.h"
#import "SRGNotificationView.h"
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

@property (nonatomic, weak) IBOutlet SRGAccessibilityView *accessibilityView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *playbackView;
@property (nonatomic, weak) IBOutlet SRGControlsView *controlsView;
@property (nonatomic, weak) UIImageView *loadingImageView;
@property (nonatomic, weak) IBOutlet SRGNotificationView *notificationView;
@property (nonatomic, weak) IBOutlet SRGLetterboxTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet SRGAvailabilityView *availabilityView;
@property (nonatomic, weak) IBOutlet SRGContinuousPlaybackView *continuousPlaybackView;
@property (nonatomic, weak) IBOutlet SRGErrorView *errorView;

@property (nonatomic) IBOutletCollection(SRGFullScreenButton) NSArray<SRGFullScreenButton *> *fullScreenButtons;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineToSafeAreaBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineToSelfBottomConstraint;

@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *showUserInterfaceTapGestureRecognizer;
@property (nonatomic, weak) IBOutlet SRGTapGestureRecognizer *videoGravityTapChangeGestureRecognizer;

@property (nonatomic) NSTimer *userInterfaceUpdateTimer;
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
        
        // The top-level view loaded from the xib file and initialized in `commonInit` is NOT an `SRGLetterboxView`. Manually
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
    
    self.accessibilityView.letterboxView = self;
    self.accessibilityView.alpha = UIAccessibilityIsVoiceOverRunning() ? 1.f : 0.f;
    
    UIImageView *loadingImageView = [UIImageView srg_loadingImageView48WithTintColor:[UIColor whiteColor]];
    loadingImageView.alpha = 0.f;
    [self insertSubview:loadingImageView aboveSubview:self.controlsView];
    [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.controlsView.mas_centerX);
        make.centerY.equalTo(self.controlsView.mas_centerY);
    }];
    self.loadingImageView = loadingImageView;
    
    self.controlsView.delegate = self;
    self.timelineView.delegate = self;
    
    self.availabilityView.alpha = 0.f;
    self.errorView.hidden = YES;
    
    self.timelineHeightConstraint.constant = 0.f;
    
    // Detect all touches on the player view. Other gesture recognizers can be added directly in the storyboard
    // to detect other interactions earlier
    SRGActivityGestureRecognizer *activityGestureRecognizer = [[SRGActivityGestureRecognizer alloc] initWithTarget:self
                                                                                                            action:@selector(resetInactivityTimer:)];
    activityGestureRecognizer.delegate = self;
    [self addGestureRecognizer:activityGestureRecognizer];
    
    self.videoGravityTapChangeGestureRecognizer.tapDelay = 0.3;
    
    BOOL fullScreenButtonHidden = [self shouldHideFullScreenButton];
    [self.fullScreenButtons enumerateObjectsUsingBlock:^(SRGFullScreenButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        button.hidden = fullScreenButtonHidden;
    }];
    
    [self reloadData];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateUserInterfaceAnimated:NO];
        [self voiceOverStatusDidChange];
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
}

#pragma mark Accessibility

- (void)voiceOverStatusDidChange
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
        
        if (previousMediaPlayerController.view.superview == self.playbackView) {
            [previousMediaPlayerController.view removeFromSuperview];
        }
    }
    
    _controller = controller;
    
    // TODO: Can be automatically made recursively
    self.controlsView.controller = controller;
    self.errorView.controller = controller;
    self.availabilityView.controller = controller;
    self.continuousPlaybackView.controller = controller;
    self.timelineView.controller = controller;
    
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
        
        [self.playbackView addSubview:mediaPlayerController.view];
        
        // Force autolayout to ensure the layout is immediately correct 
        [mediaPlayerController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playbackView);
        }];
        
        [self.playbackView layoutIfNeeded];
    }
    else {
        [self unregisterUserInterfaceUpdateTimers];
    }
    
    [self updateUserInterfaceForController:controller animated:NO];
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
    BOOL hasError = (SRGLetterboxViewErrorForController(controller) != nil);
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
    BOOL hasError = (SRGLetterboxViewErrorForController(controller) != nil);
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
    return self.controlsView.time;
}

- (NSDate *)date
{
    return self.controlsView.date;
}

- (BOOL)isLive
{
    return self.controlsView.live;
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
    [self reloadImageForController:controller];
    
    // TODO: Recursive
    [self.controlsView reloadDataForController:controller];
    [self.timelineView reloadDataForController:controller];
    [self.availabilityView reloadDataForController:controller];
    [self.continuousPlaybackView reloadDataForController:controller];
    [self.errorView reloadDataForController:controller];
}

- (void)reloadImageForController:(SRGLetterboxController *)controller
{
    // For livestreams, rely on channel information when available
    SRGMedia *media = controller.subdivisionMedia ?: controller.media;
    if (media.contentType == SRGContentTypeLivestream && controller.channel) {
        SRGChannel *channel = controller.channel;
        
        // Display program artwork (if any) when the slider position is within the current program, otherwise channel artwork.
        NSDate *date = self.controlsView.date;
        if (date && [channel.currentProgram srgletterbox_containsDate:date]) {
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

    BOOL hasError = (SRGLetterboxViewErrorForController(controller) != nil);
    BOOL hasMedia = controller.media || controller.URN;
    BOOL isContinuousPlaybackViewVisible = (controller.continuousPlaybackUpcomingMedia != nil);
    BOOL isAvailabilityViewVisible = ! [self isAvailabilityViewHiddenForController:controller] && ! isContinuousPlaybackViewVisible;
    
    self.controlsView.alpha = (! userInterfaceHidden && ! isContinuousPlaybackViewVisible) ? 1.f : 0.f;
    
    self.errorView.hidden = (! hasError && hasMedia) || isAvailabilityViewVisible || isContinuousPlaybackViewVisible;
    
    self.availabilityView.alpha = isAvailabilityViewVisible ? 1.f : 0.f;
    self.continuousPlaybackView.alpha = isContinuousPlaybackViewVisible ? 1.f : 0.f;
    
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
    CGFloat timelineHeight = SRGLetterboxViewTimelineHeight(self, userInterfaceHidden);
    self.timelineHeightConstraint.constant = timelineHeight;
    
    // Scroll to selected index when opening the timeline
    BOOL isTimelineVisible = (timelineHeight != 0.f);
    BOOL shouldFocus = (self.timelineHeightConstraint.constant == 0.f && isTimelineVisible);
    if (shouldFocus) {
        [self.timelineView scrollToSelectedIndexAnimated:NO];
    }
    
    static const CGFloat kBottomConstraintGreaterPriority = 950.f;
    static const CGFloat kBottomConstraintLesserPriority = 850.f;
    
    if (isTimelineVisible) {
        self.timelineToSafeAreaBottomConstraint.priority = kBottomConstraintGreaterPriority;
        self.timelineToSelfBottomConstraint.priority = kBottomConstraintLesserPriority;
    }
    else {
        self.timelineToSafeAreaBottomConstraint.priority = kBottomConstraintLesserPriority;
        self.timelineToSelfBottomConstraint.priority = kBottomConstraintGreaterPriority;
    }
        
    return timelineHeight;
}

// TODO: Remove, this method should not be required anymore (controls view implements it)
- (void)updateControlsLayoutForController:(SRGLetterboxController *)controller userInterfaceHidden:(BOOL)userInterfaceHidden
{
    [self.controlsView updateLayoutForController:controller view:self userInterfaceHidden:userInterfaceHidden];
    
    BOOL isLoading = SRGLetterboxViewIsLoading(self);
    if (isLoading) {
        self.loadingImageView.alpha = 1.f;
        [self.loadingImageView startAnimating];
    }
    else {
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
        CGFloat notificationHeight = [self.notificationView updateLayoutWithMessage:self.notificationMessage];
        [self updateControlsLayoutForController:controller userInterfaceHidden:userInterfaceHidden];
        
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
        [self.availabilityView reloadDataForController:controller];
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

- (IBAction)toggleFullScreen:(id)sender
{
    [self setFullScreen:!self.isFullScreen animated:YES];
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

- (void)controlsViewDidTap:(SRGControlsView *)controlsView
{
    // Defer execution to avoid conflicts with the activity gesture
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setTogglableUserInterfaceHidden:YES animated:YES];
    });
}

- (void)controlsView:(SRGControlsView *)controlsView isMovingToPlaybackTime:(CMTime)time withValue:(float)value interactive:(BOOL)interactive
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

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self voiceOverStatusDidChange];
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

NSError *SRGLetterboxViewErrorForController(SRGLetterboxController *controller)
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

CGFloat SRGLetterboxViewTimelineHeight(SRGLetterboxView *view, BOOL userInterfaceHidden)
{
    SRGLetterboxController *controller = view.controller;
    NSArray<SRGSubdivision *> *subdivisions = [view subdivisionsForMediaComposition:controller.mediaComposition];
    SRGLetterboxViewBehavior timelineBehavior = [view timelineBehaviorForController:controller];
    return (subdivisions.count != 0 && ! controller.continuousPlaybackTransitionEndDate && ((timelineBehavior == SRGLetterboxViewBehaviorNormal && ! userInterfaceHidden) || timelineBehavior == SRGLetterboxViewBehaviorForcedVisible)) ? view.preferredTimelineHeight : 0.f;
}


BOOL SRGLetterboxViewIsLoading(SRGLetterboxView *view)
{
    SRGLetterboxController *controller = view.controller;
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    
    BOOL isPlayerLoading = mediaPlayerController && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePlaying
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePaused
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded
        && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle;
    
    return isPlayerLoading || controller.dataAvailability == SRGLetterboxDataAvailabilityLoading;
}
