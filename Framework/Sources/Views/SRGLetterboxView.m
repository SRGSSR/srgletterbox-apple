//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxService.h"

#import <Masonry/Masonry.h>

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
@property (nonatomic, weak) id periodicTimeObserver;

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
    }
    else {
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
