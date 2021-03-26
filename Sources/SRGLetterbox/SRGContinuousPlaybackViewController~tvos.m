//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_TV

#import "SRGContinuousPlaybackViewController.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGImageButton.h"
#import "SRGLetterboxController+Private.h"
#import "UIColor+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

@import SRGAppearance;
@import YYWebImage;

static NSString *SRGLocalizedUppercaseString(NSString *string)
{
    NSString *firstUppercaseCharacter = [string substringToIndex:1].localizedUppercaseString;
    return [firstUppercaseCharacter stringByAppendingString:[string substringFromIndex:1]];
}

@interface SRGContinuousPlaybackViewController ()

@property (nonatomic) SRGMedia *media;
@property (nonatomic) SRGMedia *upcomingMedia;
@property (nonatomic) NSDate *endDate;

@property (nonatomic, weak) UIImageView *backgroundImageView;

@property (nonatomic, weak) SRGImageButton *thumbnailButton;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *subtitleLabel;

@property (nonatomic, weak) SRGImageButton *upcomingThumbnailButton;
@property (nonatomic, weak) UILabel *upcomingTitleLabel;
@property (nonatomic, weak) UILabel *upcomingSubtitleLabel;
@property (nonatomic, weak) UILabel *upcomingSummaryLabel;

@property (nonatomic, weak) UILabel *remainingTimeLabel;

@property (nonatomic) NSTimer *timer;

@end

@implementation SRGContinuousPlaybackViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(SRGMedia *)media upcomingMedia:(SRGMedia *)upcomingMedia endDate:(NSDate *)endDate
{
    if (self = [super init]) {
        self.media = media;
        self.upcomingMedia = upcomingMedia;
        self.endDate = endDate;
    }
    return self;
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

- (void)loadView
{
    [super loadView];
    
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.blackColor;
    self.view = view;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancel:)];
    tapGestureRecognizer.allowedPressTypes = @[ @(UIPressTypeMenu) ];
    [view addGestureRecognizer:tapGestureRecognizer];
    
    [self layoutBackgroundInView:view];
    [self layoutStackViewInView:view];
    [self layoutUpcomingStackViewInView:view];
    [self layoutFocusGuidesInView:view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reloadMetadata];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.movingToParentViewController || self.beingPresented) {
        self.backgroundImageView.image = [UIImage srg_vectorImageAtPath:SRGLetterboxFilePathForImagePlaceholder() withSize:self.backgroundImageView.frame.size];
        
        self.timer = [NSTimer srgletterbox_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self reloadTimeInformation];
        }];
        [self reloadTimeInformation];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        self.timer = nil;
    }
}

#pragma mark Layout helpers

- (UIView *)layoutFlexibleSpacerInStackView:(UIStackView *)stackView
{
    UIView *spacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:spacerView];
    return spacerView;
}

- (UIView *)layoutFixedSpacerWithHeight:(CGFloat)height inStackView:(UIStackView *)stackView
{
    UIView *spacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:spacerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [spacerView.heightAnchor constraintEqualToConstant:height]
    ]];
    
    return spacerView;
}

- (void)layoutBackgroundInView:(UIView *)view
{
    UIImageView *backgroundImageView = [[UIImageView alloc] init];
    backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:backgroundImageView];
    self.backgroundImageView = backgroundImageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [backgroundImageView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [backgroundImageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [backgroundImageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [backgroundImageView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
}

- (void)layoutStackViewInView:(UIView *)view
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentLeading;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.spacing = 20.f;
    [view addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:view.topAnchor constant:55.f],
        [stackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-55.f],
        [stackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:55.f],
        [stackView.widthAnchor constraintEqualToConstant:480.f]
    ]];
    
    [self layoutThumbnailButtonInStackView:stackView];
    [self layoutDescriptionInStackView:stackView];
    [self layoutFlexibleSpacerInStackView:stackView];
}

- (void)layoutThumbnailButtonInStackView:(UIStackView *)stackView
{
    SRGImageButton *thumbnailButton = [[SRGImageButton alloc] init];
    [thumbnailButton addTarget:self action:@selector(restart:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [stackView addArrangedSubview:thumbnailButton];
    self.thumbnailButton = thumbnailButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [thumbnailButton.widthAnchor constraintEqualToAnchor:stackView.widthAnchor],
        [thumbnailButton.widthAnchor constraintEqualToAnchor:thumbnailButton.heightAnchor multiplier:16.f / 9.f]
    ]];
}

- (void)layoutDescriptionInStackView:(UIStackView *)stackView
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 2;
    titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    titleLabel.textColor = UIColor.whiteColor;
    [stackView addArrangedSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.numberOfLines = 2;
    subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    subtitleLabel.textColor = UIColor.lightGrayColor;
    [stackView addArrangedSubview:subtitleLabel];
    self.subtitleLabel = subtitleLabel;
}

- (void)layoutUpcomingStackViewInView:(UIView *)view
{
    UIStackView *upcomingStackView = [[UIStackView alloc] init];
    upcomingStackView.translatesAutoresizingMaskIntoConstraints = NO;
    upcomingStackView.axis = UILayoutConstraintAxisVertical;
    upcomingStackView.alignment = UIStackViewAlignmentLeading;
    upcomingStackView.distribution = UIStackViewDistributionFill;
    upcomingStackView.spacing = 20.f;
    [view addSubview:upcomingStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [upcomingStackView.topAnchor constraintEqualToAnchor:view.topAnchor constant:55.f],
        [upcomingStackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-55.f],
        [upcomingStackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-55.f],
        [upcomingStackView.widthAnchor constraintEqualToConstant:880.f]
    ]];
    
    [self layoutUpcomingThumbnailButtonInStackView:upcomingStackView];
    [self layoutUpcomingDescriptionInStackView:upcomingStackView];
    [self layoutFixedSpacerWithHeight:10.f inStackView:upcomingStackView];
    [self layoutRemainingTimeLabelInStackView:upcomingStackView];
    [self layoutFlexibleSpacerInStackView:upcomingStackView];
}

- (void)layoutUpcomingThumbnailButtonInStackView:(UIStackView *)stackView
{
    SRGImageButton *upcomingThumbnailButton = [[SRGImageButton alloc] init];
    [upcomingThumbnailButton addTarget:self action:@selector(engage:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [stackView addArrangedSubview:upcomingThumbnailButton];
    self.upcomingThumbnailButton = upcomingThumbnailButton;
    
    [NSLayoutConstraint activateConstraints:@[
        [upcomingThumbnailButton.widthAnchor constraintEqualToAnchor:stackView.widthAnchor],
        [upcomingThumbnailButton.widthAnchor constraintEqualToAnchor:upcomingThumbnailButton.heightAnchor multiplier:16.f / 9.f]
    ]];
}

- (void)layoutUpcomingDescriptionInStackView:(UIStackView *)stackView
{
    UILabel *upcomingTitleLabel = [[UILabel alloc] init];
    upcomingTitleLabel.numberOfLines = 2;
    upcomingTitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    upcomingTitleLabel.textColor = UIColor.whiteColor;
    [stackView addArrangedSubview:upcomingTitleLabel];
    self.upcomingTitleLabel = upcomingTitleLabel;
    
    UILabel *upcomingSubtitleLabel = [[UILabel alloc] init];
    upcomingSubtitleLabel.numberOfLines = 2;
    upcomingSubtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    upcomingSubtitleLabel.textColor = UIColor.lightGrayColor;
    [stackView addArrangedSubview:upcomingSubtitleLabel];
    self.upcomingSubtitleLabel = upcomingSubtitleLabel;
    
    UILabel *upcomingSummaryLabel = [[UILabel alloc] init];
    upcomingSummaryLabel.numberOfLines = 3;
    upcomingSummaryLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    upcomingSummaryLabel.textColor = UIColor.whiteColor;
    [stackView addArrangedSubview:upcomingSummaryLabel];
    self.upcomingSummaryLabel = upcomingSummaryLabel;
}

- (void)layoutRemainingTimeLabelInStackView:(UIStackView *)stackView
{
    UILabel *remainingTimeLabel = [[UILabel alloc] init];
    remainingTimeLabel.numberOfLines = 3;
    remainingTimeLabel.font = [UIFont srg_mediumFontWithSize:38.f];
    remainingTimeLabel.textColor = UIColor.srg_progressRedColor;
    [stackView addArrangedSubview:remainingTimeLabel];
    self.remainingTimeLabel = remainingTimeLabel;
}

- (void)layoutFocusGuidesInView:(UIView *)view
{
    // Navigation here requires focus guides. For focus to be able to move from a focused button (slightly larger than
    // its official frame), we need the focus guides (each associated with the corresponding button) to be anchored with
    // an offset so that the focus engine can find them.
    UIFocusGuide *focusGuide1 = [[UIFocusGuide alloc] init];
    [view addLayoutGuide:focusGuide1];
    [NSLayoutConstraint activateConstraints:@[
        [focusGuide1.leadingAnchor constraintEqualToAnchor:self.thumbnailButton.trailingAnchor constant:30.f],
        [focusGuide1.topAnchor constraintEqualToAnchor:self.thumbnailButton.topAnchor],
        [focusGuide1.bottomAnchor constraintEqualToAnchor:self.thumbnailButton.bottomAnchor],
        [focusGuide1.widthAnchor constraintEqualToConstant:10.f]
    ]];
    focusGuide1.preferredFocusEnvironments = @[ self.upcomingThumbnailButton ];
    
    UIFocusGuide *focusGuide2 = [[UIFocusGuide alloc] init];
    [view addLayoutGuide:focusGuide2];
    [NSLayoutConstraint activateConstraints:@[
        [focusGuide2.trailingAnchor constraintEqualToAnchor:self.upcomingThumbnailButton.leadingAnchor constant:-30.f],
        [focusGuide2.topAnchor constraintEqualToAnchor:self.upcomingThumbnailButton.topAnchor],
        [focusGuide2.bottomAnchor constraintEqualToAnchor:self.upcomingThumbnailButton.bottomAnchor],
        [focusGuide2.widthAnchor constraintEqualToConstant:10.f]
    ]];
    focusGuide2.preferredFocusEnvironments = @[ self.thumbnailButton ];
}

#pragma mark UI

- (void)reloadMetadata
{
    self.titleLabel.text = self.media.title;
    self.titleLabel.isAccessibilityElement = NO;
    
    self.subtitleLabel.text = [self subtitleForMedia:self.media];
    self.subtitleLabel.isAccessibilityElement = NO;
    
    self.thumbnailButton.accessibilityLabel = self.media.title;
    self.thumbnailButton.accessibilityHint = SRGLetterboxAccessibilityLocalizedString(@"Plays the content.", @"Segment or chapter cell hint");
    [self.thumbnailButton.imageView srg_requestImageForObject:self.media withScale:SRGImageScaleMedium type:SRGImageTypeDefault];
    
    self.upcomingTitleLabel.text = self.upcomingMedia.title;
    self.upcomingTitleLabel.isAccessibilityElement = NO;
    
    self.upcomingSubtitleLabel.text = [self subtitleForMedia:self.upcomingMedia];
    self.upcomingSubtitleLabel.isAccessibilityElement = NO;
    
    self.upcomingSummaryLabel.text = self.upcomingMedia.summary;
    self.upcomingSummaryLabel.isAccessibilityElement = NO;
    
    self.upcomingThumbnailButton.accessibilityHint = SRGLetterboxAccessibilityLocalizedString(@"Plays the content.", @"Segment or chapter cell hint");
    [self.upcomingThumbnailButton.imageView srg_requestImageForObject:self.upcomingMedia withScale:SRGImageScaleMedium type:SRGImageTypeDefault];
}

- (void)reloadTimeInformation
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    });
    
    NSTimeInterval remainingTimeInterval = floor([self.endDate timeIntervalSinceDate:NSDate.date]);
    NSString *remainingTimeDescription = nil;
    if (remainingTimeInterval > 0.) {
        NSString *remainingTimeString = [s_dateComponentsFormatter stringFromDate:NSDate.date toDate:self.endDate];
        remainingTimeDescription = [NSString stringWithFormat:SRGLetterboxLocalizedString(@"Starts in %@", @"Message displayed to inform that next content will start in \"X seconds\"."), remainingTimeString];
    }
    else {
        remainingTimeDescription = SRGLetterboxLocalizedString(@"Starting…", @"Message displayed to inform that next content should start soon.");
    }
    
    self.upcomingThumbnailButton.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", self.upcomingMedia.title, remainingTimeDescription];
    self.remainingTimeLabel.text = remainingTimeDescription;
}

- (NSString *)subtitleForMedia:(SRGMedia *)media
{
    if (media.contentType != SRGContentTypeLivestream) {
        NSString *showTitle = media.show.title;
        if (showTitle && ! [media.title containsString:showTitle]) {
            return [NSString stringWithFormat:@"%@ - %@", showTitle, SRGLocalizedUppercaseString([NSDateFormatter.srgletterbox_relativeDateAndTimeFormatter stringFromDate:media.date])];
        }
        else {
            return SRGLocalizedUppercaseString([NSDateFormatter.srgletterbox_relativeDateAndTimeFormatter stringFromDate:media.date]);
        }
    }
    else {
        return nil;
    }
}

#pragma mark Overrides

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[ self.upcomingThumbnailButton ];
}

#pragma mark Actions

- (void)engage:(id)sender
{
    [self.delegate continuousPlaybackViewController:self didEngageInContinuousPlaybackWithUpcomingMedia:self.upcomingMedia];
}

- (void)restart:(id)sender
{
    [self.delegate continuousPlaybackViewController:self didRestartPlaybackWithMedia:self.media cancelledUpcomingMedia:self.upcomingMedia];
}

- (void)cancel:(id)sender
{
    [self.delegate continuousPlaybackViewController:self didCancelContinuousPlaybackWithUpcomingMedia:self.upcomingMedia];
}

@end

#endif
