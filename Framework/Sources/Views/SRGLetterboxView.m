//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxService.h"

#import <Masonry/Masonry.h>
#import <libextobjc/libextobjc.h>

@class ASValueTrackingSlider;

@interface SRGLetterboxView ()

// UI
@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *controlsView;
@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playbackButton;
@property (nonatomic, weak) IBOutlet ASValueTrackingSlider *timeSlider;
@property (nonatomic, weak) IBOutlet UIButton *forwardSeekButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardSeekButton;

@property (nonatomic, weak) UIImageView *loadingImageView;

@property (nonatomic, weak) IBOutlet UIView *errorView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;

@property (nonatomic, weak) IBOutlet SRGPictureInPictureButton *pictureInPictureButton;

@property (nonatomic, weak) IBOutlet SRGAirplayView *airplayView;
@property (nonatomic, weak) IBOutlet UILabel *airplayLabel;
@property (nonatomic, weak) IBOutlet SRGAirplayButton *airplayButton;
@property (nonatomic, weak) IBOutlet SRGTracksButton *tracksButton;
@property (nonatomic, weak) IBOutlet UIButton *fullScreenButton;


// Internal
@property (nonatomic) NSTimer *inactivityTimer;
@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, getter=isUserInterfaceHidden) BOOL userInterfaceHidden;
@property (nonatomic, getter=isShowingPopup) BOOL showingPopup;

@end

@implementation SRGLetterboxView

#pragma mark View life cycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    SRGLetterboxController *letterboxController = [SRGLetterboxService sharedService].controller;
    [self.playerView insertSubview:letterboxController.view aboveSubview:self.imageView];
    [letterboxController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerView);
    }];
    
    self.playbackButton.mediaPlayerController = letterboxController;
    
    self.backwardSeekButton.hidden = YES;
    self.forwardSeekButton.hidden = YES;
    
    self.pictureInPictureButton.mediaPlayerController = letterboxController;
    
    self.airplayView.mediaPlayerController = letterboxController;
    self.airplayView.delegate = self;
    
    self.airplayButton.mediaPlayerController = letterboxController;
    self.tracksButton.mediaPlayerController = letterboxController;
    
    // Detect all touches on the player view. Other gesture recognizers can be added directly in the storyboard
    // to detect other interactions earlier
    SRGActivityGestureRecognizer *activityGestureRecognizer = [[SRGActivityGestureRecognizer alloc] initWithTarget:self
                                                                                                            action:@selector(resetInactivityTimer:)];
    activityGestureRecognizer.delegate = self;
    [self.playerView addGestureRecognizer:activityGestureRecognizer];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        SRGLetterboxController *letterboxController = [SRGLetterboxService sharedService].controller;
        @weakify(self)
        @weakify(letterboxController)
        self.periodicTimeObserver = [letterboxController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            @strongify(letterboxController)
            
            self.forwardSeekButton.hidden = ![letterboxController canSeekForward];
            self.backwardSeekButton.hidden = ![letterboxController canSeekBackward];
        }];
        [self updateInterfaceAnimated:NO];
    }
    else {
        self.inactivityTimer = nil;                 // Invalidate timer
        [[SRGLetterboxService sharedService].controller removePeriodicTimeObserver:self.periodicTimeObserver];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self xibSetup];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self xibSetup];
    }
    return self;
}

-(void)xibSetup {
    
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

#pragma mark Getters and setters

- (void)setInactivityTimer:(NSTimer *)inactivityTimer
{
    [_inactivityTimer invalidate];
    _inactivityTimer = inactivityTimer;
}

# pragma mark UI

- (void)setUserInterfaceHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.userInterfaceHidden == hidden) {
        return;
    }
    
    // Cannot toggle UI when an error is displayed
    if (! self.errorView.hidden) {
        return;
    }
    
    void (^animations)(void) = ^{
        CGFloat alpha = hidden ? 0.f : 1.f;
        self.controlsView.alpha = alpha;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished) {
            self.userInterfaceHidden = hidden;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations completion:completion];
    }
    else {
        animations();
        completion(YES);
    }
}

- (void)updateInterfaceAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        SRGLetterboxController *letterboxController = [SRGLetterboxService sharedService].controller;
        
        if (letterboxController.playbackState == SRGMediaPlayerPlaybackStatePlaying) {
            // Hide if playing a video in Airplay or if true screen mirroring is used
            SRGMedia *media = [SRGLetterboxService sharedService].media;
            BOOL hidden = (media.mediaType == SRGMediaTypeVideo) && (! [AVAudioSession srg_isAirplayActive] || ([UIScreen srg_isMirroring] && ! letterboxController.player.usesExternalPlaybackWhileExternalScreenIsActive));
            self.imageView.alpha = hidden ? 0.f : 1.f;
            letterboxController.view.alpha = hidden ? 1.f : 0.f;
            
            [self resetInactivityTimer];
            
            if (!self.showingPopup) {
                self.showingPopup = YES;
                [self.timeSlider showPopUpViewAnimated:YES];
            }
        }
        else if (letterboxController.playbackState == SRGMediaPlayerPlaybackStateEnded) {
            self.imageView.alpha = 1.f;
            letterboxController.view.alpha = 0.f;
            
            [self.timeSlider hidePopUpViewAnimated:YES];
            self.showingPopup = NO;
            
            [self setUserInterfaceHidden:NO animated:YES];
        }
        
        self.loadingImageView.alpha = (letterboxController.playbackState == SRGMediaPlayerPlaybackStatePlaying
                                       || letterboxController.playbackState == SRGMediaPlayerPlaybackStatePaused
                                       || letterboxController.playbackState == SRGMediaPlayerPlaybackStateEnded
                                       || letterboxController.playbackState == SRGMediaPlayerPlaybackStateIdle) ? 0.f : 1.f;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)resetInactivityTimer
{
    self.inactivityTimer = [NSTimer scheduledTimerWithTimeInterval:4. target:self selector:@selector(hideInterface:) userInfo:nil repeats:NO];
}

#pragma mark Gesture recognizers

- (void)resetInactivityTimer:(UIGestureRecognizer *)gestureRecognizer
{
    [self resetInactivityTimer];
    [self setUserInterfaceHidden:NO animated:YES];
}

- (IBAction)toggleUserInterfaceVisibility:(UIGestureRecognizer *)gestureRecognizer
{
    [self setUserInterfaceHidden:! self.userInterfaceHidden animated:YES];
}

#pragma mark Timers

- (void)hideInterface:(NSTimer *)timer
{
    // Only auto-hide the UI when it makes sense (e.g. not when the player is paused or loading). When the state
    // of the player returns to playing, the inactivity timer will be reset (see -playbackStateDidChange:)
    SRGLetterboxController *letterboxController = [SRGLetterboxService sharedService].controller;
    if (letterboxController.playbackState == SRGMediaPlayerPlaybackStatePlaying
        || letterboxController.playbackState == SRGMediaPlayerPlaybackStateSeeking
        || letterboxController.playbackState == SRGMediaPlayerPlaybackStateStalled) {
        [self setUserInterfaceHidden:YES animated:YES];
    }
}

#pragma mark Actions

- (IBAction)seekBackward:(id)sender
{
    [[SRGLetterboxService sharedService].controller seekBackwardWithCompletionHandler:nil];
}

- (IBAction)seekForward:(id)sender
{
    [[SRGLetterboxService sharedService].controller seekForwardWithCompletionHandler:nil];
}

#pragma mark ASValueTrackingSliderDataSource protocol

- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value;
{
    SRGMedia *media = [SRGLetterboxService sharedService].media;
    if (media.contentType == SRGContentTypeLivestream) {
        return (self.timeSlider.isLive) ? NSLocalizedString(@"Live", nil) : self.timeSlider.valueString;
    }
    else {
        return self.timeSlider.valueString ?: @"--:--";
    }
}

#pragma mark SRGAirplayViewDelegate protocol

- (void)airplayView:(SRGAirplayView *)airplayView didShowWithAirplayRouteName:(NSString *)routeName
{
    self.airplayLabel.text = SRGAirplayRouteDescription();
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
