//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuousPlaybackViewController.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "UIImageView+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>
#import <YYWebImage/YYWebImage.h>

@interface SRGContinuousPlaybackViewController ()

@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMedia *upcomingMedia;
@property (nonatomic) NSDate *endDate;

@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;

@property (nonatomic, weak) IBOutlet UIButton *thumbnailButton;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, weak) IBOutlet UIButton *upcomingThumbnailButton;
@property (nonatomic, weak) IBOutlet UILabel *upcomingTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *upcomingSummaryLabel;

@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;

@property (nonatomic) NSTimer *timer;

@end

@implementation SRGContinuousPlaybackViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(SRGMedia *)media upcomingMedia:(SRGMedia *)upcomingMedia endDate:(NSDate *)endDate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:SRGLetterboxResourceNameForUIClass(self.class) bundle:NSBundle.srg_letterboxBundle];
    SRGContinuousPlaybackViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    viewController.upcomingMedia = upcomingMedia;
    viewController.endDate = endDate;
    return viewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMedia:SRGMedia.new upcomingMedia:SRGMedia.new endDate:NSDate.new];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (void)setTimer:(NSTimer *)timer
{
    [_timer invalidate];
    _timer = timer;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundImageView.image = [UIImage srg_vectorImageAtPath:SRGLetterboxMediaPlaceholderFilePath() withSize:self.backgroundImageView.frame.size];
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    
    self.upcomingTitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.upcomingSummaryLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    self.remainingTimeLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancel:)];
    tapGestureRecognizer.allowedPressTypes = @[ @(UIPressTypeMenu) ];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    [self setupFocusGuides];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.movingToParentViewController || self.beingPresented) {
        self.timer = [NSTimer srgletterbox_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self reloadData];
        }];
        [self reloadData];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        self.timer = nil;
    }
}

#pragma mark UI

- (void)reloadData
{
    NSURL *URL = [NSURL URLWithString:@"https://www.rts.ch/2019/10/27/16/28/10813484.image/16x9/scale/width/688"];
    
    self.titleLabel.text = self.media.title;
    [self.thumbnailButton yy_setImageWithURL:URL forState:UIControlStateNormal options:0];
    
    self.upcomingTitleLabel.text = self.upcomingMedia.title;
    self.upcomingSummaryLabel.text = self.upcomingMedia.summary;
    [self.upcomingThumbnailButton yy_setImageWithURL:URL forState:UIControlStateNormal options:0];
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    });
    
    NSTimeInterval remainingTimeInterval = floor([self.endDate timeIntervalSinceDate:NSDate.date]);
    if (remainingTimeInterval != 0.) {
        NSString *remainingTimeString = [s_dateComponentsFormatter stringFromDate:NSDate.date toDate:self.endDate];
        self.remainingTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Starts in %@", nil), remainingTimeString];
    }
    else {
        self.remainingTimeLabel.text = NSLocalizedString(@"Starting...", nil);
    }
}

- (void)setupFocusGuides
{
    // Navigation here requires focus guides. For focus to be able to move from a focused button (slightly larger than
    // its official frame), we need the focus guides (each associated with the corresponding button) to be anchored with
    // an offset so that the focus engine can find them.
    UIFocusGuide *focusGuide1 = [[UIFocusGuide alloc] init];
    [self.view addLayoutGuide:focusGuide1];
    [NSLayoutConstraint activateConstraints:@[
        [focusGuide1.leadingAnchor constraintEqualToAnchor:self.thumbnailButton.trailingAnchor constant:30.f],
        [focusGuide1.topAnchor constraintEqualToAnchor:self.thumbnailButton.topAnchor],
        [focusGuide1.bottomAnchor constraintEqualToAnchor:self.thumbnailButton.bottomAnchor],
        [focusGuide1.widthAnchor constraintEqualToConstant:10.f]
    ]];
    if (@available(tvOS 10, *)) {
        focusGuide1.preferredFocusEnvironments = @[ self.upcomingThumbnailButton ];
    }
    else {
        focusGuide1.preferredFocusedView = self.upcomingThumbnailButton;
    }
    
    UIFocusGuide *focusGuide2 = [[UIFocusGuide alloc] init];
    [self.view addLayoutGuide:focusGuide2];
    [NSLayoutConstraint activateConstraints:@[
        [focusGuide2.trailingAnchor constraintEqualToAnchor:self.upcomingThumbnailButton.leadingAnchor constant:-30.f],
        [focusGuide2.topAnchor constraintEqualToAnchor:self.upcomingThumbnailButton.topAnchor],
        [focusGuide2.bottomAnchor constraintEqualToAnchor:self.upcomingThumbnailButton.bottomAnchor],
        [focusGuide2.widthAnchor constraintEqualToConstant:10.f]
    ]];
    if (@available(tvOS 10, *)) {
        focusGuide2.preferredFocusEnvironments = @[ self.thumbnailButton ];
    }
    else {
        focusGuide2.preferredFocusedView = self.thumbnailButton;
    }
}

#pragma mark Overrides

- (CGRect)preferredPlayerViewFrame
{
    static const CGFloat kWidth = 720.f;
    return CGRectMake(80.f, 80.f, kWidth, kWidth * 9.f / 16.f);
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[ self.upcomingThumbnailButton ];
}

#pragma mark Actions

- (IBAction)engage:(id)sender
{
    [self.delegate continuousPlaybackViewController:self didEngageInContinuousPlaybackWithUpcomingMedia:self.upcomingMedia];
}

- (IBAction)restart:(id)sender
{
    [self.delegate continuousPlaybackViewController:self didRestartPlaybackWithMedia:self.media];
}

- (void)cancel:(id)sender
{
    [self.delegate continuousPlaybackViewController:self didCancelContinuousPlaybackWithUpcomingMedia:self.upcomingMedia];
}

@end
