//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuousPlaybackView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGRemainingTimeButton.h"
#import "UIImageView+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

static void commonInit(SRGContinuousPlaybackView *self);

@interface SRGContinuousPlaybackView ()

@property (nonatomic, weak) IBOutlet UILabel *introLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet SRGRemainingTimeButton *remainingTimeButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic) NSTimer *continuousPlaybackTransitionTimer;

@end

@implementation SRGContinuousPlaybackView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
        
        // The top-level view loaded from the xib file and initialized in `commonInit` is NOT an SRGContinuousPlaybackView. Manually
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
    // Invalidate timers
    self.continuousPlaybackTransitionTimer = nil;
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        [_controller removeObserver:self keyPath:@keypath(_controller.continuousPlaybackUpcomingMedia)];
    }
    
    _controller = controller;
    
    if (controller) {
        @weakify(self)
        [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self refreshViewAnimated:YES];
        }];
    }
    
    [self refreshViewAnimated:NO];
}

- (void)setContinuousPlaybackTransitionTimer:(NSTimer *)continuousPlaybackTransitionTimer
{
    [_continuousPlaybackTransitionTimer invalidate];
    _continuousPlaybackTransitionTimer = continuousPlaybackTransitionTimer;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.introLabel.text = SRGLetterboxLocalizedString(@"Next", @"For continuous playback, introductory label for content which is about to start");
    [self.cancelButton setTitle:SRGLetterboxLocalizedString(@"Cancel", @"Title of a cancel button") forState:UIControlStateNormal];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChange:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        
        [self refreshViewAnimated:NO];
        [self updateFonts];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIContentSizeCategoryDidChangeNotification
                                                      object:nil];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height < 100.f) {
        self.introLabel.hidden = YES;
        self.titleLabel.hidden = YES;
        self.subtitleLabel.hidden = YES;
        self.cancelButton.hidden = YES;
    }
    else if (height < 150.f) {
        self.introLabel.hidden = YES;
        self.titleLabel.hidden = NO;
        self.subtitleLabel.hidden = YES;
        self.cancelButton.hidden = YES;
    }
    else if (height < 200.f) {
        self.introLabel.hidden = YES;
        self.titleLabel.hidden = NO;
        self.subtitleLabel.hidden = YES;
        self.cancelButton.hidden = NO;
    }
    else {
        self.introLabel.hidden = NO;
        self.titleLabel.hidden = NO;
        self.subtitleLabel.hidden = NO;
        self.cancelButton.hidden = NO;
    }
}

#pragma mark UI

- (void)refreshViewAnimated:(BOOL)animated
{
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    self.titleLabel.text = upcomingMedia.title;
    self.subtitleLabel.text = upcomingMedia.lead ?: upcomingMedia.summary;
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    
    [self.imageView srg_requestImageForObject:upcomingMedia withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
    
    NSTimeInterval duration = [self.controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate];
    float progress = (duration != 0) ? ([NSDate.date timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate]) / duration : 1.f;
    [self.remainingTimeButton setProgress:progress withDuration:duration];
    
    self.continuousPlaybackTransitionTimer = nil;
    NSTimeInterval remainingInterval = [self.controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:NSDate.date];
    if (remainingInterval > 0) {
        @weakify(self)
        self.continuousPlaybackTransitionTimer = [NSTimer srg_scheduledTimerWithTimeInterval:duration repeats:NO block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            
            if (self.delegate) {
                [self.delegate continuousPlaybackView:self didEndContinuousPlaybackTransitionWithMedia:upcomingMedia selected:NO];
            }
        }];
    }
}

#pragma mark Fonts

- (void)updateFonts
{
    self.introLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.titleLabel.font = [UIFont srg_boldFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.cancelButton.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

#pragma mark Actions

- (IBAction)cancelContinuousPlayback:(id)sender
{
    self.continuousPlaybackTransitionTimer = nil;
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    
    [self.controller cancelContinuousPlayback];
    
    if (self.delegate) {
        [self.delegate continuousPlaybackView:self didCancelContinuousPlaybackTransitionWithMedia:upcomingMedia];
    }
}

- (IBAction)playNextMedia:(id)sender
{
    self.continuousPlaybackTransitionTimer = nil;
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    
    [self.controller playNextMedia];
    
    if (self.delegate) {
        [self.delegate continuousPlaybackView:self didEndContinuousPlaybackTransitionWithMedia:upcomingMedia selected:YES];
    }
}

#pragma mark Notifications

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

@end

static void commonInit(SRGContinuousPlaybackView *self)
{
    // This makes design in a xib and Interface Builder preview (IB_DESIGNABLE) work. The top-level view must NOT be
    // an SRGCountdownView to avoid infinite recursion
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    view.backgroundColor = [UIColor clearColor];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}
