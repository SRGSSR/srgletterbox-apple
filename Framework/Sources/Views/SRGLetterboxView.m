//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
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
#import "SRGMedia+SRGLetterbox.h"
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

@property (nonatomic, weak) IBOutlet UIView *availabilityView;
@property (nonatomic, weak) IBOutlet UILabel *availabilityLabel;

@property (nonatomic) NSTimer *userInterfaceUpdateTimer;

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

@property (nonatomic, copy) NSString *notificationMessage;

@property (nonatomic, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;
@property (nonatomic, getter=isUserInterfaceTogglable) BOOL userInterfaceTogglable;

@property (nonatomic, getter=isFullScreen) BOOL fullScreen;
@property (nonatomic, getter=isFullScreenAnimationRunning) BOOL fullScreenAnimationRunning;

@property (nonatomic) CGFloat preferredTimelineHeight;

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
    self.controller = nil;                   // Unregister everything
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
    self.availabilityView.alpha = 0.f;
    
    self.accessibilityView.letterboxView = self;
    self.accessibilityView.alpha = UIAccessibilityIsVoiceOverRunning() ? 1.f : 0.f;
    
    self.controlsView.delegate = self;
    self.timelineView.delegate = self;
    
    self.timeSlider.resumingAfterSeek = NO;
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
        [self updateUserInterfaceAnimated:NO];
        [self updateAccessibility];
        [self updateFonts];
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
        
        // Automatically resumes in the view when displayed and if picture in picture was active
        if ([SRGLetterboxService sharedService].controller == self.controller) {
            [[SRGLetterboxService sharedService] stopPictureInPictureRestoreUserInterface:NO];
        }
        
        [self showAirplayNotificationMessageIfNeededAnimated:NO];
    }
    else {
        // Invalidate timers
        self.inactivityTimer = nil;
        self.userInterfaceUpdateTimer = nil;
        
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
}

#pragma mark Fonts

- (void)updateFonts
{
    self.errorLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.errorInstructionsLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.notificationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.timeSlider.timeLeftValueLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    [self updateAvailabilityLabelForController:self.controller];
}

#pragma mark Accessibility

- (void)updateAccessibility
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        self.accessibilityView.alpha = 1.f;
        [self toggleUserInterfaceHidden:NO animated:YES];
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
        self.userInterfaceUpdateTimer = nil;
        
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
        
        if (previousMediaPlayerController.view.superview == self.playerView) {
            [previousMediaPlayerController.view removeFromSuperview];
        }
        
        [self updateAvailabilityLabelForController:controller];
    }
    
    _controller = controller;
    
    SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
    self.playbackButton.mediaPlayerController = mediaPlayerController;
    self.pictureInPictureButton.mediaPlayerController = mediaPlayerController;
    self.airplayButton.mediaPlayerController = mediaPlayerController;
    self.tracksButton.mediaPlayerController = mediaPlayerController;
    self.timeSlider.mediaPlayerController = mediaPlayerController;
    
    // Notifications are transient and therefore do not need to be persisted at the controller level. They can be simply
    // cleaned up when the controller changes.
    self.notificationMessage = nil;
    
    [self reloadDataForController:controller];
    
    if (controller) {
        SRGMediaPlayerController *mediaPlayerController = controller.mediaPlayerController;
        
        @weakify(self)
        @weakify(controller)
        self.userInterfaceUpdateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            @strongify(controller)
            [self updateUserInterfaceForController:controller animated:YES];
            [self updateAvailabilityLabelForController:controller];
        }];
        
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
        
        [self.playerView addSubview:mediaPlayerController.view];
        
        // Force autolayout to ensure the layout is immediately correct 
        [mediaPlayerController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playerView);
        }];
        
        [self.playerView layoutIfNeeded];
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
    NSError *error = self.controller.error;
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
    
    [self updateAvailabilityLabelForController:controller];
}

- (void)updateAvailabilityLabelForController:(SRGLetterboxController *)controller
{
    SRGMedia *media = controller.media;
    self.availabilityLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    if (media.srg_availability == SRGMediaAvailabilityExpired) {
        self.availabilityLabel.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"Expired", @"Label to explain that a content has expired").uppercaseString];
        self.availabilityLabel.hidden = NO;
    }
    else if (media.srg_availability == SRGMediaAvailabilityNotYet) {
        NSTimeInterval timeIntervalBeforeStart = [media.startDate ?: media.date timeIntervalSinceDate:NSDate.date];
        
        NSString *availabilityLabelText = nil;
        if (timeIntervalBeforeStart > 60. * 60.) {
            static NSDateComponentsFormatter *s_longDateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_longDateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_longDateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;
                s_longDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad | NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
            });
            availabilityLabelText = [s_longDateComponentsFormatter stringFromTimeInterval:timeIntervalBeforeStart];
        }
        else {
            static NSDateComponentsFormatter *s_shortDateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_shortDateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_shortDateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour;
                s_shortDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
            });
            availabilityLabelText = [s_shortDateComponentsFormatter stringFromTimeInterval:timeIntervalBeforeStart];
        }
        
        if (media.contentType == SRGContentTypeLivestream || media.contentType == SRGContentTypeScheduledLivestream) {
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", availabilityLabelText]
                                                                                               attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                                                                             NSForegroundColorAttributeName : [UIColor whiteColor] }];
            
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"●  ")
                                                                                   attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                                                                 NSForegroundColorAttributeName : [UIColor whiteColor] }]];
            
            self.availabilityLabel.attributedText = [attributedText copy];
        }
        else {
            self.availabilityLabel.text = [NSString stringWithFormat:@"  %@  ", availabilityLabelText];
        }
        
        static NSDateComponentsFormatter *s_accessibilityDateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_accessibilityDateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_accessibilityDateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay;
            s_accessibilityDateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
            s_accessibilityDateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        self.availabilityLabel.accessibilityLabel = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_accessibilityDateComponentsFormatter stringFromTimeInterval:timeIntervalBeforeStart]];
        self.availabilityLabel.hidden = NO;
    }
    else {
        self.availabilityLabel.text = nil;
        self.availabilityLabel.accessibilityLabel = nil;
        self.availabilityLabel.hidden = YES;
    }
}

- (void)reloadImageForController:(SRGLetterboxController *)controller
{
    // For livestreams, rely on channel information when available
    SRGMedia *media = controller.media;
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

- (void)toggleUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
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
    
    // Controls and error overlay must never be displayed at the same time. This does not change the final expected
    // control visbility state variable, only its visual result.
    BOOL hasError = ([self error] != nil);
    BOOL isUsingAirplay = [AVAudioSession srg_isAirplayActive]
        && (controller.media.mediaType == SRGMediaTypeAudio || mediaPlayerController.player.externalPlaybackActive);
    
    BOOL userInterfaceHidden = self.userInterfaceHidden;
    BOOL isMediaAvailable = (controller.media.srg_availability == SRGMediaAvailabilityAvailable);
    if (hasError || ! isMediaAvailable || controller.dataAvailability == SRGLetterboxDataAvailabilityLoading) {
        userInterfaceHidden = YES;
    }
    else if (self.userInterfaceTogglable
                && (playbackState == SRGMediaPlayerPlaybackStateEnded || isUsingAirplay || controller.dataAvailability == SRGLetterboxDataAvailabilityNone)) {
        userInterfaceHidden = NO;
    }
    
    self.controlsView.alpha = userInterfaceHidden ? 0.f : 1.f;
    self.backgroundInteractionView.alpha = userInterfaceHidden ? 0.f : 1.f;
    
    self.notificationImageView.hidden = (self.notificationMessage == nil);
    self.notificationLabelBottomConstraint.constant = (self.notificationMessage != nil) ? 6.f : 0.f;
    self.notificationLabelTopConstraint.constant = (self.notificationMessage != nil) ? 6.f : 0.f;

    // Only display retry instructions if there is a media to retry with
    self.errorView.alpha = hasError ? 1.f : 0.f;
    self.errorInstructionsLabel.alpha = (hasError && controller.URN) ? 1.f : 0.f;
    
    self.availabilityView.alpha = isMediaAvailable ? 0.f : 1.f;
    
    // Hide video view if a video in AirPlay or if "true screen mirroring" is used (device screen copy with no full-screen
    // playback on the external device)
    SRGMedia *media = controller.media;
    BOOL playerViewHidden = (media.mediaType == SRGMediaTypeVideo) && ! mediaPlayerController.externalNonMirroredPlaybackActive
        && playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStatePreparing && playbackState != SRGMediaPlayerPlaybackStateEnded;
    self.imageView.alpha = playerViewHidden ? 0.f : 1.f;
    mediaPlayerController.view.alpha = playerViewHidden ? 1.f : 0.f;
    
    return userInterfaceHidden;
}

- (CGFloat)updateTimelineLayoutForController:(SRGLetterboxController *)controller userInterfaceHidden:(BOOL)userInterfaceHidden
{
    NSArray<SRGSubdivision *> *subdivisions = [self subdivisionsForMediaComposition:controller.mediaComposition];
    CGFloat timelineHeight = (subdivisions.count != 0 && ! userInterfaceHidden) ? self.preferredTimelineHeight : 0.f;
    
    // Scroll to selected index when opening the timeline
    BOOL shouldFocus = (self.timelineHeightConstraint.constant == 0.f && timelineHeight != 0.f);
    self.timelineHeightConstraint.constant = timelineHeight;
    
    if (shouldFocus) {
        [self.timelineView scrollToSelectedIndexAnimated:NO];
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
        self.seekToLiveButton.alpha = 0.f;
        
        self.timeSlider.alpha = 0.f;
        self.timeSlider.timeLeftValueLabel.hidden = YES;
        self.playbackButton.usesStopImage = NO;
    }
    else {
        self.forwardSeekButton.alpha = [controller canSkipForward] ? 1.f : 0.f;
        self.backwardSeekButton.alpha = [controller canSkipBackward] ? 1.f : 0.f;
        self.seekToLiveButton.alpha = [controller canSkipToLive] ? 1.f : 0.f;
        
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
    }
    
    // Pop-up visibility
    if (mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateIdle
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStatePreparing
            || mediaPlayerController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        [self.timeSlider hidePopUpViewAnimated:NO];
    }
    else {
        [self.timeSlider showPopUpViewAnimated:NO];
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
                [self toggleUserInterfaceHidden:YES animated:YES];
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
    [self toggleUserInterfaceHidden:NO animated:YES];
}

- (IBAction)hideUserInterface:(UIGestureRecognizer *)gestureRecognizer
{
    // Defer execution to avoid conflicts with the activity gesture above
    dispatch_async(dispatch_get_main_queue(), ^{
        [self toggleUserInterfaceHidden:YES animated:YES];
    });
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

#pragma mark SRGASValueTrackingSliderDataSource protocol

- (NSAttributedString *)slider:(SRGASValueTrackingSlider *)slider attributedStringForValue:(float)value
{
    if (self.controller.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeLive || self.controller.mediaPlayerController.streamType == SRGMediaPlayerStreamTypeDVR) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"  ") attributes:@{ NSFontAttributeName : [UIFont srg_awesomeFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }];
        NSDate *date = slider.date;
        
        NSString *string = nil;
        if (slider.live) {
            string = SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live stream or a timeshift stream in live");
        }
        else if (date) {
            static dispatch_once_t s_onceToken;
            static NSDateFormatter *s_dateFormatter;
            dispatch_once(&s_onceToken, ^{
                s_dateFormatter = [[NSDateFormatter alloc] init];
                s_dateFormatter.dateStyle = NSDateFormatterNoStyle;
                s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
            });
            
            string = [s_dateFormatter stringFromDate:date];
        }
        else {
            string = SRGLetterboxNonLocalizedString(@"--:--");
        }
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }]];
        
        return [attributedString copy];
    }
    else {
        return [[NSAttributedString alloc] initWithString:slider.valueString ?: SRGLetterboxNonLocalizedString(@"--:--") attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle] }];
    }
}

- (void)setNeedsSubdivisionFavoritesUpdate
{
    [self.timelineView setNeedsSubdivisionFavoritesUpdate];
}

#pragma mark SRGControlsViewDelegate protocol

- (void)controlsViewDidLayoutSubviews:(SRGControlsView *)controlsView
{
    // Larger image set starting with iPhone Plus in landscape orientation
    SRGImageSet imageSet = (CGRectGetWidth(self.playerView.bounds) < 668.f) ? SRGImageSetNormal : SRGImageSetLarge;
    CGFloat horizontalSpacing = (imageSet == SRGImageSetNormal) ? 0.f : 20.f;
    
    self.horizontalSpacingPlaybackToBackwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingPlaybackToForwardConstraint.constant = horizontalSpacing;
    self.horizontalSpacingForwardToSeekToLiveConstraint.constant = horizontalSpacing;
    
    self.playbackButton.imageSet = imageSet;
    
    [self.backwardSeekButton setImage:[UIImage srg_letterboxSeekBackwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.forwardSeekButton setImage:[UIImage srg_letterboxSeekForwardImageInSet:imageSet] forState:UIControlStateNormal];
    [self.seekToLiveButton setImage:[UIImage srg_letterboxSeekToLiveImageInSet:imageSet] forState:UIControlStateNormal];
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
    NSString *notificationMessage = SRGMessageForSkippedSegmentWithBlockingReason(subdivision.blockingReason);
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
    
    self.preferredTimelineHeight = SRGLetterboxViewDefaultTimelineHeight;
}
