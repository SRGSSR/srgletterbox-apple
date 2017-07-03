//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGAccessibilityView.h"
#import "SRGASValueTrackingSlider.h"
#import "SRGControlsView.h"
#import "SRGFullScreenButton.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxError.h"
#import "SRGLetterboxLogger.h"
#import "SRGLetterboxPlaybackButton.h"
#import "SRGLetterboxService+Private.h"
#import "SRGLetterboxTimelineView.h"
#import "SRGLetterboxViewRestorationContext.h"
#import "SRGProgram+SRGLetterbox.h"
#import "UIFont+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGAppearance/SRGAppearance.h>
#import <libextobjc/libextobjc.h>
#import <Masonry/Masonry.h>

const CGFloat SRGLetterboxViewDefaultTimelineHeight = 120.f;

static void commonInit(SRGLetterboxView *self);

@interface SRGLetterboxView () <SRGASValueTrackingSliderDataSource, SRGLetterboxTimelineViewDelegate, SRGControlsViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic, weak) IBOutlet SRGControlsView *controlsView;
@property (nonatomic, weak) IBOutlet SRGLetterboxPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *forwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *seekToLiveButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToBackwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingPlaybackToForwardConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpacingForwardToSeekToLiveConstraint;

@property (nonatomic, weak) IBOutlet UIView *backgroundInteractionView;
@property (nonatomic, weak) IBOutlet SRGAccessibilityView *accessibilityView;

@property (nonatomic, weak) UIImageView *loadingImageView;

@property (nonatomic, weak) IBOutlet UIView *errorView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;
@property (nonatomic, weak) IBOutlet UILabel *errorInstructionsLabel;

@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;
@property (nonatomic, weak) IBOutlet SRGASValueTrackingSlider *timeSlider;
@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;
@property (nonatomic) IBOutletCollection(SRGFullScreenButton) NSArray<SRGFullScreenButton *> *fullScreenButtons;

@property (nonatomic, weak) IBOutlet UIView *notificationView;

@property (nonatomic, weak) IBOutlet UIImageView *notificationImageView;
@property (nonatomic, weak) IBOutlet UILabel *notificationLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *notificationLabelTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *notificationLabelBottomConstraint;

@property (nonatomic, weak) IBOutlet SRGLetterboxTimelineView *timelineView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timelineHeightConstraint;

@property (nonatomic) NSTimer *inactivityTimer;
@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, copy) NSString *notificationMessage;

@property (nonatomic, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;
@property (nonatomic, getter=isUserInterfaceTogglable) BOOL userInterfaceTogglable;

@property (nonatomic) NSNumber *finalUserInterfaceHidden;                                                           // Final userInterfaceHidden value when an animation is taking place (nil if none)
@property (nonatomic, readonly, getter=isEffectiveUserInterfaceHidden) BOOL effectiveUserInterfaceHidden;           // Final userInterfaceHidden value if available, current value if none

@property (nonatomic, getter=isFullScreen) BOOL fullScreen;
@property (nonatomic, getter=isFullScreenAnimationRunning) BOOL fullScreenAnimationRunning;

@property (nonatomic, getter=isShowingPopup) BOOL showingPopup;
@property (nonatomic) CGFloat preferredTimelineHeight;

@property (nonatomic) SRGLetterboxViewRestorationContext *mainRestorationContext;                       // Context of the values supplied by the user
@property (nonatomic) NSMutableArray<SRGLetterboxViewRestorationContext *> *restorationContexts;        // Contexts piled up internally on top of the main user context

// Get the future notification height, with the `layoutForNotificationHeight`method
@property (nonatomic, readonly) CGFloat notificationHeight;

@property (nonatomic, copy) void (^animations)(BOOL hidden, CGFloat heightOffset);
@property (nonatomic, copy) void (^completion)(BOOL finished);

@end

@implementation SRGLetterboxView {
@private
    BOOL _inWillAnimateUserInterface;
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
    self.controller = nil;          // Unregister everything
}

#pragma mark View lifecycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIImageView *loadingImageView = [UIImageView srg_loadingImageView35WithTintColor:[UIColor whiteColor]];
    loadingImageView.alpha = 0.f;
    [self.mainView insertSubview:loadingImageView aboveSubview:self.playbackButton];
    [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.playbackButton.mas_centerX);
        make.centerY.equalTo(self.playbackButton.mas_centerY);
    }];
    self.loadingImageView = loadingImageView;
    
    self.errorInstructionsLabel.text = SRGLetterboxLocalizedString(@"Tap to retry", @"Message displayed when an error has occurred and the ability to retry");
    
    self.backwardSeekButton.alpha = 0.f;
    self.forwardSeekButton.alpha = 0.f;
    self.seekToLiveButton.alpha = 0.f;
    self.timeSlider.alpha = 0.f;
    self.timeSlider.timeLeftValueLabel.hidden = YES;
    self.errorView.alpha = 0.f;
    
    self.accessibilityView.letterboxView = self;
    self.accessibilityView.alpha = UIAccessibilityIsVoiceOverRunning() ? 1.f : 0.f;
    
    self.controlsView.delegate = self;
    self.timelineView.delegate = self;
    
    self.timeSlider.resumingAfterSeek = YES;
    self.timeSlider.popUpViewColor = UIColor.whiteColor;
    self.timeSlider.textColor = UIColor.blackColor;
    self.timeSlider.popUpViewWidthPaddingFactor = 1.5f;
    self.timeSlider.popUpViewHeightPaddingFactor = 1.f;
    self.timeSlider.popUpViewCornerRadius = 3.f;
    self.timeSlider.popUpViewArrowLength = 4.f;
    self.timeSlider.dataSource = self;
    self.timeSlider.delegate = self;
    
    self.timelineHeightConstraint.constant = 0.f;
    
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
    self.seekToLiveButton.accessibilityLabel = SRGLetterboxAccessibilityLocalizedString(@"Back to live", @"Back to live label");
        
    [self reloadData];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateVisibleSubviewsAnimated:NO];
        [self updateUserInterfaceForServicePlayback];
        [self updateUserInterfaceForAirplayAnimated:NO];
        [self updateUserInterfaceForErrorAnimated:NO];
        [self updateLoadingIndicatorAnimated:NO];
        [self updateUserInterfaceAnimated:NO];
        [self accessibilityVoiceOverStatusChanged:nil];
        [self reloadData];
        
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
        
        [self updateFonts];
        
        // Automatically resumes in the view when displayed and if picture in picture was active
        if ([SRGLetterboxService sharedService].controller == self.controller) {
            [[SRGLetterboxService sharedService] stopPictureInPictureRestoreUserInterface:NO];
        }
        
        [self showAirplayNotificationMessageIfNeededAnimated:NO];
    }
    else {
        self.inactivityTimer = nil;                 // Invalidate timer
        
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
    
    // We need to know what will be the notification height, depending of the notification message and the layout resizing.
    if (self.notificationMessage && CGRectGetHeight(self.notificationImageView.frame) != 0.f) {
        
        [self layoutNotificationView];
        if (self.notificationHeight != CGRectGetHeight(self.notificationImageView.frame)) {
            [self updateUserInterfaceAnimated:YES];
        }
    }
}

#pragma mark Fonts

- (void)updateFonts
{
    self.errorLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.errorInstructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.notificationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.timeSlider.timeLeftValueLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller == controller) {
        return;
    }
    
    if (_controller) {
        SRGMediaPlayerController *previousMediaPlayerController = _controller.mediaPlayerController;
        [previousMediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxMetadataDidChangeNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackDidFailNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackDidRestartNotification
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
        
        if (previousMediaPlayerController.view.superview == self.playerView) {
            [previousMediaPlayerController.view removeFromSuperview];
        }
    }
    
    _controller = controller;
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    self.playbackButton.mediaPlayerController = mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airplayButton.mediaPlayerController = mediaPlayerController;
    self.tracksButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
    // Synchronize the slider popup and the loading indicator with the new controller state
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        [self.timeSlider hidePopUpViewAnimated:NO];
    }
    else {
        [self.timeSlider showPopUpViewAnimated:NO];
    }
    
    // Notifications are transient and therefore do not need to be persisted at the controller level. They can be simply
    // cleaned up when the controller changes.
    self.notificationMessage = nil;
    
    [self updateLoadingIndicatorForController:controller animated:NO];
    [self updateUserInterfaceForErrorAnimated:NO];
    [self updateUserInterfaceAnimated:NO];
    [self reloadDataForController:controller];
    
    if (controller) {
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        
        @weakify(self)
        @weakify(controller)
        self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            @strongify(controller)
            [self updateControlsForController:controller animated:YES];
        }];
        [self updateControlsForController:controller animated:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(metadataDidChange:)
                                                     name:SRGLetterboxMetadataDidChangeNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidFail:)
                                                     name:SRGLetterboxPlaybackDidFailNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackDidRestart:)
                                                     name:SRGLetterboxPlaybackDidRestartNotification
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
        
        [self.playerView addSubview:mediaPlayerController.view];
        
        // Force autolayout to ensure the layout is immediately correct 
        [mediaPlayerController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playerView);
        }];
        
        [self.playerView layoutIfNeeded];
    }
}

- (void)setDelegate:(id<SRGLetterboxViewDelegate>)delegate
{
    _delegate = delegate;
    
    BOOL fullScreenButtonHidden = [self shouldHideFullScreenButton];
    [self.fullScreenButtons enumerateObjectsUsingBlock:^(SRGFullScreenButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        button.hidden = fullScreenButtonHidden;
    }];
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
        }
        self.fullScreenAnimationRunning = NO;
    }];
}

- (void)setInactivityTimer:(NSTimer *)inactivityTimer
{
    [_inactivityTimer invalidate];
    _inactivityTimer = inactivityTimer;
}

- (NSError *)error
{
    if (self.controller.error) {
        return self.controller.error;
    }
    else if (! self.controller.media && ! self.controller.URN) {
        return [NSError errorWithDomain:SRGLetterboxErrorDomain
                                   code:SRGLetterboxErrorCodeNotFound
                               userInfo:@{ NSLocalizedDescriptionKey : SRGLetterboxLocalizedString(@"No media", @"Text displayed when no media is available for playback") }];
    }
    else {
        return nil;
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
    return self.preferredTimelineHeight != 0;
}

- (void)setTimelineAlwaysHidden:(BOOL)timelineAlwaysHidden animated:(BOOL)animated
{
    [self setPreferredTimelineHeight:(timelineAlwaysHidden ? 0.f : SRGLetterboxViewDefaultTimelineHeight) animated:animated];
}

- (CGFloat)timelineHeight
{
    return self.timelineHeightConstraint.constant;
}

- (BOOL)isEffectiveUserInterfaceHidden
{
    return self.finalUserInterfaceHidden ? self.finalUserInterfaceHidden.boolValue : self.userInterfaceHidden;
}

- (CMTime)time
{
    return self.timeSlider.time;
}

- (BOOL)isLive
{
    return self.timeSlider.live;
}

#pragma mark Data display

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
    
    self.timelineView.subdivisions = [self subdivisionsForMediaComposition:mediaComposition];
    self.timelineView.selectedIndex = subdivision ? [self.timelineView.subdivisions indexOfObject:subdivision] : NSNotFound;
    
    [self reloadImageForController:controller];
    
    self.errorLabel.text = [self error].localizedDescription;
}

- (void)reloadImageForController:(SRGLetterboxController *)controller
{
    // For livestreams, rely on channel information when available
    SRGMedia *media = controller.media;
    if (media.contentType == SRGContentTypeLivestream && controller.channel) {
        SRGChannel *channel = controller.channel;
        
        // Display program artwork (if any) when the slider position is within the current program, otherwise channel artwork.
        NSDate *sliderDate = [NSDate dateWithTimeIntervalSinceNow:self.timeSlider.value - self.timeSlider.maximumValue];
        if ([channel.currentProgram srgletterbox_containsDate:sliderDate]) {
            if (! [self.imageView srg_requestImageForObject:channel.currentProgram withScale:SRGImageScaleLarge type:SRGImageTypeDefault]) {
                [self.imageView srg_requestImageForObject:channel withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
            }
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

#pragma mark UI public methods

// Public method for changing user interface visibility only. Always update visibility, except when a UI state has been
// forced (in which case changes will be applied after restoration)
- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    SRGLetterboxViewRestorationContext *previousContext = self.mainRestorationContext;
    
    self.mainRestorationContext = [[SRGLetterboxViewRestorationContext alloc] initWithName:@"main"];
    self.mainRestorationContext.hidden = hidden;
    self.mainRestorationContext.togglable = previousContext.togglable;
    
    if (self.restorationContexts.count != 0) {
        return;
    }
    
    [self imperative_setUserInterfaceHidden:hidden animated:animated togglable:previousContext.togglable];
}

// Public method for changing user interface behavior. Always update interface settings, except when a UI state has been
// forced (in which case changes will be applied after restoration)
- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable
{
    self.mainRestorationContext = [[SRGLetterboxViewRestorationContext alloc] initWithName:@"main"];
    self.mainRestorationContext.hidden = hidden;
    self.mainRestorationContext.togglable = togglable;
    
    if (self.restorationContexts.count != 0) {
        return;
    }
    
    [self imperative_setUserInterfaceHidden:hidden animated:animated togglable:togglable];
}

#pragma mark UI methods subject to conditional execution

// Show or hide the user interface, doing nothing if the interface is not togglable or in an overridden state
- (void)conditional_setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (! self.userInterfaceTogglable || self.restorationContexts.count != 0) {
        return;
    }
    
    if (self.effectiveUserInterfaceHidden == hidden) {
        return;
    }
    
    NSArray<SRGSubdivision *> *subdivisions = [self subdivisionsForMediaComposition:self.controller.mediaComposition];
    [self imperative_updateUserInterfaceHidden:hidden withSubdivisions:subdivisions animated:animated];
}

#pragma mark UI methods always performing their work

- (void)imperative_setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable
{
    self.userInterfaceTogglable = togglable;
    
    NSArray<SRGSubdivision *> *subdivisions = [self subdivisionsForMediaComposition:self.controller.mediaComposition];
    [self imperative_updateUserInterfaceHidden:hidden withSubdivisions:subdivisions animated:animated];
}

- (void)imperative_updateUserInterfaceWithSubdivisions:(NSArray<SRGSubdivision *> *)subdivisions animated:(BOOL)animated
{
    [self imperative_updateUserInterfaceHidden:self.effectiveUserInterfaceHidden withSubdivisions:subdivisions animated:animated];
}

// Common implementation for -setUserInterfaceHidden:... methods. Use a distinct name to make aware this is an internal
// factorisation method which is not intended for direct use. This method always shows or hides the user interface. Subdivisions
// and notification message text are taken into account for proper UI adjustments depending on their presence
- (void)imperative_updateUserInterfaceHidden:(BOOL)hidden withSubdivisions:(NSArray<SRGSubdivision *> *)subdivisions animated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(letterboxViewWillAnimateUserInterface:)]) {
        _inWillAnimateUserInterface = YES;
        [self.delegate letterboxViewWillAnimateUserInterface:self];
        _inWillAnimateUserInterface = NO;
    }
    
    // Always scroll to the selected subdivision when opening the timeline. Schedule for scrolling on the next run loop so
    // that scrolling actually can work (no scrolling occurs when cells are not considered visible).
    CGFloat timelineHeight = (subdivisions.count != 0 && ! hidden) ? self.preferredTimelineHeight : 0.f;
    if (timelineHeight != 0.f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.timelineView scrollToSelectedIndexAnimated:NO];
        });
    }
    
    self.finalUserInterfaceHidden = @(hidden);
    
    void (^animations)(void) = ^{
        self.controlsView.alpha = hidden ? 0.f : 1.f;
        self.backgroundInteractionView.alpha = hidden ? 0.f : 1.f;
        self.timelineHeightConstraint.constant = timelineHeight;
        
        self.notificationImageView.hidden = (self.notificationMessage == nil);
        self.notificationLabelBottomConstraint.constant = (self.notificationMessage != nil) ? 6.f : 0.f;
        self.notificationLabelTopConstraint.constant = (self.notificationMessage != nil) ? 6.f : 0.f;
        
        // We need to know what will be the notification view height, depending of the new notification message.
        self.notificationLabel.text = self.notificationMessage;
        [self layoutNotificationView];
        
        self.animations ? self.animations(hidden, timelineHeight + self.notificationHeight) : nil;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished) {
            self.userInterfaceHidden = hidden;
            self.finalUserInterfaceHidden = nil;
        }
        
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

#pragma mark UI changes and restoration

// Apply changes to the user interface and save previous values with the specified identifier. Changes for a given
// identifier are applied at most once. Synchronous.
- (void)imperative_setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated togglable:(BOOL)togglable withRestorationIdentifier:(NSString *)restorationIdentifier
{
    SRGLetterboxViewRestorationContext *restorationContext = [[SRGLetterboxViewRestorationContext alloc] initWithName:restorationIdentifier];
    restorationContext.hidden = hidden;
    restorationContext.togglable = togglable;
    
    if (! [self.restorationContexts containsObject:restorationContext]) {
        [self.restorationContexts addObject:restorationContext];
        [self imperative_setUserInterfaceHidden:hidden animated:animated togglable:togglable];
    }
}

// Restore the user interface state as if the change identified by the identifiers was not made. The suggested user interface state
// is provided in the `changes` block. Synchronous.
- (void)imperative_restoreUserInterfaceForIdentifier:(NSString *)restorationIdentifier animated:(BOOL)animated
{
    SRGLetterboxViewRestorationContext *restorationContext = [[SRGLetterboxViewRestorationContext alloc] initWithName:restorationIdentifier];
    if ([self.restorationContexts containsObject:restorationContext]) {
        [self.restorationContexts removeObject:restorationContext];
        
        SRGLetterboxViewRestorationContext *restorationContext = self.restorationContexts.lastObject ?: self.mainRestorationContext;
        [self imperative_setUserInterfaceHidden:restorationContext.hidden animated:animated togglable:restorationContext.togglable];
    }
}

#pragma mark UI updates

// Force a UI refresh for the current settings and subdivisions
- (void)updateUserInterfaceAnimated:(BOOL)animated
{
    NSArray<SRGSubdivision *> *subdivisions = [self subdivisionsForMediaComposition:self.controller.mediaComposition];
    [self imperative_updateUserInterfaceHidden:self.effectiveUserInterfaceHidden withSubdivisions:subdivisions animated:animated];
}

// Called to update the main player subviews (player view, background image, error overlay). Independent of the global
// status of the control overlay
- (void)updateVisibleSubviewsAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
        SRGMediaPlayerPlaybackState playbackState = mediaPlayerController.playbackState;
        
        if (playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            // Hide if playing a video in Airplay or if "true screen mirroring" is used (device screen copy with no full-screen
            // playback on the external device)
            SRGMedia *media = self.controller.media;
            BOOL hidden = (media.mediaType == SRGMediaTypeVideo) && ! mediaPlayerController.externalNonMirroredPlaybackActive;
            self.imageView.alpha = hidden ? 0.f : 1.f;
            mediaPlayerController.view.alpha = hidden ? 1.f : 0.f;
            
            [self resetInactivityTimer];
            
            if (!self.showingPopup) {
                self.showingPopup = YES;
                [self.timeSlider showPopUpViewAnimated:NO /* already in animation block */];
            }
        }
        else if (playbackState == SRGMediaPlayerPlaybackStateEnded
                    || playbackState == SRGMediaPlayerPlaybackStateIdle) {
            self.imageView.alpha = 1.f;
            mediaPlayerController.view.alpha = 0.f;
            
            [self.timeSlider hidePopUpViewAnimated:NO /* already in animation block */];
            self.showingPopup = NO;
            
            // Force display of the controls at the end of the playback
            if (playbackState == SRGMediaPlayerPlaybackStateEnded) {
                [self conditional_setUserInterfaceHidden:NO animated:NO /* already in animation block */];
            }
        }
        else if (playbackState == SRGMediaPlayerPlaybackStatePaused) {
            [self conditional_setUserInterfaceHidden:NO animated:NO /* already in animation block */];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)updateControlsForController:(SRGLetterboxController *)controller animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        self.forwardSeekButton.alpha = [controller canSkipForward] ? 1.f : 0.f;
        self.backwardSeekButton.alpha = [controller canSkipBackward] ? 1.f : 0.f;
        self.seekToLiveButton.alpha = [controller canSkipToLive] ? 1.f : 0.f;
        
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        
        SRGImageSet imageSet = [self imageSet];
        self.playbackButton.imageSet = imageSet;
        
        // Special cases when the player is idle or preparing
        if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
                || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing) {
            self.timeSlider.alpha = 0.f;
            self.timeSlider.timeLeftValueLabel.hidden = YES;
            self.playbackButton.usesStopImage = NO;
            return;
        }
        
        // Adjust the UI to best match type of the stream being played
        switch (mediaPlayerController.streamType) {
            case SRGMediaPlayerStreamTypeOnDemand: {
                self.timeSlider.alpha = 1.f;
                self.timeSlider.timeLeftValueLabel.hidden = NO;
                self.playbackButton.usesStopImage = NO;
                break;
            }
                
            case SRGMediaPlayerStreamTypeLive: {
                self.timeSlider.alpha = 0.f;
                self.timeSlider.timeLeftValueLabel.hidden = NO;
                self.playbackButton.usesStopImage = YES;
                break;
            }
                
            case SRGMediaPlayerStreamTypeDVR: {
                self.timeSlider.alpha = 1.f;
                // Hide timeLeftValueLabel to give the width space to the timeSlider
                self.timeSlider.timeLeftValueLabel.hidden = YES;
                self.playbackButton.usesStopImage = NO;
                break;
            }
                
            default: {
                self.timeSlider.alpha = 0.f;
                self.timeSlider.timeLeftValueLabel.hidden = YES;
                self.playbackButton.usesStopImage = NO;
                break;
            }
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)updateControlsAnimated:(BOOL)animated
{
    [self updateControlsForController:self.controller animated:animated];
}

- (void)updateUserInterfaceForAirplayAnimated:(BOOL)animated
{
    static NSString * const kRestorationIdentifier = @"airplay";
    
    if ([AVAudioSession srg_isAirplayActive]
            && (self.controller.media.mediaType == SRGMediaTypeAudio || self.controller.mediaPlayerController.player.externalPlaybackActive)) {
        // If the user interface is togglable, show controls, use visibility as set by the API client. We do not want controls
        // to be displayed while using Airplay if the interface was forced to be hidden
        BOOL hidden = self.userInterfaceTogglable ? NO : self.mainRestorationContext.hidden;
        [self imperative_setUserInterfaceHidden:hidden animated:animated togglable:NO withRestorationIdentifier:kRestorationIdentifier];
    }
    else {
        [self imperative_restoreUserInterfaceForIdentifier:kRestorationIdentifier animated:animated];
    }
}

- (void)updateUserInterfaceForErrorAnimated:(BOOL)animated
{
    static NSString * const kRestorationIdentifier = @"error";
    
    if ([self error]) {
        self.errorView.alpha = 1.f;
        
        // Only display retry instructions if there is a media to retry with
        self.errorInstructionsLabel.alpha = self.controller.URN ? 1.f : 0.f;
        
        [self imperative_setUserInterfaceHidden:YES animated:animated togglable:NO withRestorationIdentifier:kRestorationIdentifier];
    }
    else {
        self.errorView.alpha = 0.f;
        
        [self imperative_restoreUserInterfaceForIdentifier:kRestorationIdentifier animated:animated];
    }
}

- (void)updateLoadingIndicatorForController:(SRGLetterboxController *)controller animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        BOOL isPlayerLoading = mediaPlayerController && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePlaying
            && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStatePaused
            && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateEnded
            && mediaPlayerController.playbackState != SRGMediaPlayerPlaybackStateIdle;
        BOOL isWaitingForData = ! controller.contentURLOverridden && ! controller.mediaComposition && controller.URN && ! controller.error;
        
        BOOL visible = isPlayerLoading || isWaitingForData;
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
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)updateLoadingIndicatorAnimated:(BOOL)animated
{
    [self updateLoadingIndicatorForController:self.controller animated:animated];
}

- (void)updateUserInterfaceForServicePlayback
{
    self.airplayButton.alwaysHidden = ! self.controller.backgroundServicesEnabled;
    self.pictureInPictureButton.alwaysHidden = ! self.controller.pictureInPictureEnabled;
}

- (void)resetInactivityTimer
{
    self.inactivityTimer = (! UIAccessibilityIsVoiceOverRunning()) ? [NSTimer scheduledTimerWithTimeInterval:4. target:self selector:@selector(hideInterface:) userInfo:nil repeats:NO] : nil;
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

#pragma mark Layout

- (void)layoutNotificationView
{
    // Force autolayout
    [self.notificationView setNeedsLayout];
    [self.notificationView layoutIfNeeded];
    
    // Return the minimum size which satisfies the constraints. Put a strong requirement on width and properly let the height
    // adjusts
    // For an explanation, see http://titus.io/2015/01/13/a-better-way-to-autosize-in-ios-8.html
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.width = CGRectGetWidth(self.notificationView.frame);
    _notificationHeight = [self.notificationView systemLayoutSizeFittingSize:fittingSize
                                                   withHorizontalFittingPriority:UILayoutPriorityRequired
                                                         verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
}

// Ajust control size to fit view width best.
- (void)updateControlSet
{
    SRGImageSet imageSet = [self imageSet];
    CGFloat horizontalSpacing = (imageSet == SRGImageSetNormal) ? 0.f : 20.f;
    
    self.horizontalSpacingPlaybackToBackwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingPlaybackToForwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingForwardToSeekToLiveConstraint.constant = horizontalSpacing;
    
    self.playbackButton.imageSet = imageSet;
    
    [self.backwardSeekButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSeekButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.seekToLiveButton setImage:[UIImage srg_letterboxSeekToLiveImageInSet:imageSet] forState:UIControlStateNormal];
}

- (SRGImageSet)imageSet
{
    // iPhone Plus in landscape
    return (CGRectGetWidth(self.playerView.bounds) < 668.f) ? SRGImageSetNormal : SRGImageSetLarge;
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
    [self conditional_setUserInterfaceHidden:NO animated:YES];
}

- (IBAction)hideUserInterface:(UIGestureRecognizer *)gestureRecognizer
{
    // Defer execution to avoid conflicts with the activity gesture above
    dispatch_async(dispatch_get_main_queue(), ^{
        [self conditional_setUserInterfaceHidden:YES animated:YES];
    });
}

#pragma mark Timers

- (void)hideInterface:(NSTimer *)timer
{
    // Only auto-hide the UI when it makes sense (e.g. not when the player is paused or loading). When the state
    // of the player returns to playing, the inactivity timer will be reset (see -playbackStateDidChange:)
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePlaying
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateSeeking
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateStalled) {
        [self conditional_setUserInterfaceHidden:YES animated:YES];
    }
}

#pragma mark Actions

- (IBAction)seekBackward:(id)sender
{
    [self.controller skipBackwardWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToPlaybackTime:self.timeSlider.time withValue:self.timeSlider.value interactive:YES];
    }];
}

- (IBAction)seekForward:(id)sender
{
    [self.controller skipForwardWithCompletionHandler:^(BOOL finished) {
        [self timeSlider:self.timeSlider isMovingToPlaybackTime:self.timeSlider.time withValue:self.timeSlider.value interactive:YES];
    }];
}

- (IBAction)toggleFullScreen:(id)sender
{
    [self setFullScreen:!self.isFullScreen animated:YES];
}

- (IBAction)seekToLive:(id)sender
{
    [self.controller skipToLiveWithCompletionHandler:nil];
}

- (IBAction)retry:(id)sender
{
    [self.controller stop];
    [self.controller restart];
}

#pragma mark SRGASValueTrackingSliderDataSource protocol

- (NSAttributedString *)slider:(SRGASValueTrackingSlider *)slider attributedStringForValue:(float)value;
{
    if (self.controller.media.contentType == SRGContentTypeLivestream || self.controller.media.contentType == SRGContentTypeScheduledLivestream) {
        static dispatch_once_t onceToken;
        static NSDateFormatter *dateFormatter;
        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterNoStyle;
            dateFormatter.timeStyle = NSDateFormatterShortStyle;
        });
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"  ") attributes:@{ NSFontAttributeName : [UIFont srg_awesomeFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }];
        
        NSString *string = (self.timeSlider.isLive) ? SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live stream or a timeshift stream in live") : [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:self.timeSlider.value - self.timeSlider.maximumValue]];
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }]];
        
        return [attributedString copy];
    }
    else {
        return [[NSAttributedString alloc] initWithString:self.timeSlider.valueString ?: SRGLetterboxNonLocalizedString(@"--:--") attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }];
    }
}

- (void)setNeedsSubdivisionFavoritesUpdate
{
    [self.timelineView setNeedsSubdivisionFavoritesUpdate];
}

#pragma mark SRGControlsViewDelegate protocol

- (void)controlsViewDidLayoutSubviews:(SRGControlsView *)controlsView
{
    [self updateControlSet];
}

#pragma mark SRGLetterboxTimelineViewDelegate protocol

- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didSelectSubdivision:(SRGSubdivision *)subdivision
{
    if (! [self.controller switchToSubdivision:subdivision]) {
        return;
    }
    
    self.timelineView.selectedIndex = [timelineView.subdivisions indexOfObject:subdivision];
    self.timelineView.time = subdivision.srg_timeRange.start;
    
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

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self updateVisibleSubviewsAnimated:YES];
    [self reloadData];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    self.timelineView.selectedIndex = NSNotFound;
    self.timelineView.time = kCMTimeZero;
    
    [self updateVisibleSubviewsAnimated:YES];
    [self updateUserInterfaceForErrorAnimated:YES];
    [self updateLoadingIndicatorAnimated:YES];
    [self reloadData];
}

- (void)playbackDidRestart:(NSNotification *)notification
{
    [self updateLoadingIndicatorAnimated:YES];
    [self updateUserInterfaceForErrorAnimated:YES];
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self updateVisibleSubviewsAnimated:YES];
    [self updateUserInterfaceForErrorAnimated:YES];
    [self updateUserInterfaceForAirplayAnimated:YES];
    [self updateControlsAnimated:YES];
    [self updateLoadingIndicatorAnimated:YES];
    
    SRGMediaPlayerPlaybackState playbackState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
    SRGMediaPlayerPlaybackState previousPlaybackState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
    if (playbackState == SRGMediaPlayerPlaybackStatePlaying && previousPlaybackState == SRGMediaPlayerPlaybackStatePreparing) {
        [self updateUserInterfaceAnimated:YES];
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
    else if (playbackState == SRGMediaPlayerPlaybackStateIdle) {
        [self dismissNotificationViewAnimated:YES];
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
    NSString *notificationMessage = SRGMessageForSkippedSegmentWithBlockingReason(subdivision.blockingReason);
    [self showNotificationMessage:notificationMessage animated:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updateVisibleSubviewsAnimated:YES];
}

- (void)wirelessRouteDidChange:(NSNotification *)notification
{
    [self updateVisibleSubviewsAnimated:YES];
    [self updateUserInterfaceForAirplayAnimated:YES];
    [self showAirplayNotificationMessageIfNeededAnimated:YES];
}

- (void)screenDidConnect:(NSNotification *)notification
{
    [self updateVisibleSubviewsAnimated:YES];
}

- (void)screenDidDisconnect:(NSNotification *)notification
{
    [self updateVisibleSubviewsAnimated:YES];
}

- (void)serviceSettingsDidChange:(NSNotification *)notification
{
    [self reloadData];
    [self updateVisibleSubviewsAnimated:YES];
    [self updateUserInterfaceForAirplayAnimated:YES];
    [self updateUserInterfaceForServicePlayback];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        self.accessibilityView.alpha = 1.f;
        [self conditional_setUserInterfaceHidden:NO animated:YES];
    }
    else {
        self.accessibilityView.alpha = 0.f;
    }
    
    [self resetInactivityTimer];
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
    
    self.preferredTimelineHeight = SRGLetterboxViewDefaultTimelineHeight;
    
    // Create an initial matching restoration context
    self.mainRestorationContext = [[SRGLetterboxViewRestorationContext alloc] initWithName:@"main"];
    self.mainRestorationContext.hidden = self.userInterfaceHidden;
    self.mainRestorationContext.togglable = self.userInterfaceTogglable;
    
    self.restorationContexts = [NSMutableArray array];
}
