//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGCountdownView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSLayoutConstraint+SRGLetterboxPrivate.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGPaddedLabel.h"

@import libextobjc;
@import SRGAppearance;

static const NSInteger SRGCountdownViewDaysLimit = 100;

#if TARGET_OS_TV
static const CGFloat kTitleHeight = 60.f;
static const CGFloat kMessageLabelTopSpace = 10.f;
#else
static const CGFloat kTitleHeight = 30.f;
static const CGFloat kMessageLabelTopSpace = 0.f;
#endif

@interface SRGCountdownView ()

@property (nonatomic, readonly) NSTimeInterval currentRemainingTimeInterval;

@property (nonatomic, weak) UIStackView *mainStackView;

@property (nonatomic, weak) UIStackView *daysStackView;

@property (nonatomic, weak) UILabel *days1Label;
@property (nonatomic, weak) UILabel *days0Label;
@property (nonatomic, weak) UILabel *daysTitleLabel;

@property (nonatomic, weak) UIStackView *hoursStackView;

@property (nonatomic, weak) UILabel *hoursColonLabel;
@property (nonatomic, weak) UILabel *hours1Label;
@property (nonatomic, weak) UILabel *hours0Label;
@property (nonatomic, weak) UILabel *hoursTitleLabel;

@property (nonatomic, weak) UILabel *minutesColonLabel;
@property (nonatomic, weak) UILabel *minutes1Label;
@property (nonatomic, weak) UILabel *minutes0Label;
@property (nonatomic, weak) UILabel *minutesTitleLabel;

@property (nonatomic, weak) UILabel *seconds1Label;
@property (nonatomic, weak) UILabel *seconds0Label;
@property (nonatomic, weak) UILabel *secondsTitleLabel;

// Spacers surrounding the countdown itself
@property (nonatomic, weak) UIView *secondsTopSpacerView;
@property (nonatomic, weak) UIView *secondsBottomSpacerView;
@property (nonatomic, weak) UIView *mainLeadingSpacerView;
@property (nonatomic, weak) UIView *mainTrailingSpacerView;

@property (nonatomic) NSArray<UIStackView *> *digitsStackViews;
@property (nonatomic) NSArray<UILabel *> *colonLabels;

@property (nonatomic) NSArray<NSLayoutConstraint *> *widthConstraints;
@property (nonatomic) NSArray<NSLayoutConstraint *> *heightConstraints;

@property (nonatomic, weak) SRGPaddedLabel *messageLabel;
@property (nonatomic, weak) SRGPaddedLabel *remainingTimeLabel;

@property (nonatomic, weak) UIView *accessibilityFrameView;

@property (nonatomic) NSDate *targetDate;
@property (nonatomic) NSTimer *updateTimer;

@end

@implementation SRGCountdownView

#pragma mark Object lifecycle

- (instancetype)initWithTargetDate:(NSDate *)targetDate frame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.targetDate = targetDate;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithTargetDate:NSDate.date frame:CGRectZero];
}

#pragma mark Layout

- (void)layoutContentView
{
    [super layoutContentView];
    
    [self layoutMainStackViewInView:self.contentView];
    [self layoutMessageLabelInView:self.contentView];
    [self layoutRemainingTimeLabelInView:self.contentView];
    [self layoutAccessibilityFrameInView:self.contentView];
}

- (UIView *)layoutFlexibleSpacerInStackView:(UIStackView *)stackView
{
    UIView *spacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:spacerView];
    return spacerView;
}

- (UIStackView *)layoutTimeUnitStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *timeUnitStackView = [[UIStackView alloc] init];
    timeUnitStackView.axis = UILayoutConstraintAxisVertical;
    timeUnitStackView.alignment = UIStackViewAlignmentFill;
    timeUnitStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:timeUnitStackView];
    return timeUnitStackView;
}

- (UIStackView *)layoutDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *digitsStackView = [[UIStackView alloc] init];
    digitsStackView.axis = UILayoutConstraintAxisHorizontal;
    digitsStackView.alignment = UIStackViewAlignmentFill;
    digitsStackView.distribution = UIStackViewDistributionFill;
    digitsStackView.spacing = 2.f;
    [stackView addArrangedSubview:digitsStackView];
    return digitsStackView;
}

- (UILabel *)layoutColonLabelInStackView:(UIStackView *)stackView
{
    UILabel *colonLabel = [[UILabel alloc] init];
    colonLabel.text = @":";
    colonLabel.textAlignment = NSTextAlignmentCenter;
    colonLabel.textColor = UIColor.whiteColor;
    [colonLabel setContentHuggingPriority:252 forAxis:UILayoutConstraintAxisHorizontal];
    [stackView addArrangedSubview:colonLabel];
    return colonLabel;
}

- (UILabel *)layoutDigitLabelInStackView:(UIStackView *)stackView
{
    UILabel *digitLabel = [[UILabel alloc] init];
    digitLabel.textColor = UIColor.whiteColor;
    digitLabel.backgroundColor = UIColor.blackColor;
    digitLabel.textAlignment = NSTextAlignmentCenter;
    digitLabel.layer.masksToBounds = YES;
    [stackView addArrangedSubview:digitLabel];
    return digitLabel;
}

- (UILabel *)layoutTimeUnitLabelInView:(UIView *)view
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:titleLabel];
    return titleLabel;
}

- (void)layoutMainStackViewInView:(UIView *)view
{
    self.digitsStackViews = [NSArray array];
    self.colonLabels = [NSArray array];
    self.widthConstraints = [NSArray array];
    self.heightConstraints = [NSArray array];
    
    UIStackView *mainStackView = [[UIStackView alloc] init];
    mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
    mainStackView.axis = UILayoutConstraintAxisHorizontal;
    mainStackView.alignment = UIStackViewAlignmentFill;
    mainStackView.distribution = UIStackViewDistributionFill;
    mainStackView.spacing = 3.f;
    [view addSubview:mainStackView];
    self.mainStackView = mainStackView;
    
    [NSLayoutConstraint activateConstraints:@[
        [mainStackView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor],
        [mainStackView.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor],
        [mainStackView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
        [mainStackView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor]
    ]];
    
    self.mainLeadingSpacerView = [self layoutFlexibleSpacerInStackView:mainStackView];
    [self layoutDaysStackViewInStackView:mainStackView];
    [self layoutHoursStackViewInStackView:mainStackView];
    [self layoutMinutesStackViewInStackView:mainStackView];
    [self layoutSecondsStackViewInStackView:mainStackView];
    [self layoutInvisibleColonInStackView:mainStackView];
    self.mainTrailingSpacerView = [self layoutFlexibleSpacerInStackView:mainStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mainLeadingSpacerView.widthAnchor constraintEqualToAnchor:self.mainTrailingSpacerView.widthAnchor]
    ]];
}

- (void)layoutDaysStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *daysStackView = [self layoutTimeUnitStackViewInStackView:stackView];
    self.daysStackView = daysStackView;
    
    NSLayoutConstraint *daysStackViewWidthConstraint = [[daysStackView.widthAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:daysStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        daysStackViewWidthConstraint
    ]];
    
    UIView *daysTopSpacerView = [self layoutFlexibleSpacerInStackView:daysStackView];
    [self layoutDaysDigitsStackViewInStackView:daysStackView];
    [self layoutDaysTitleViewInStackView:daysStackView];
    UIView *daysBottomSpacerView = [self layoutFlexibleSpacerInStackView:daysStackView];;
    
    [NSLayoutConstraint activateConstraints:@[
        [daysTopSpacerView.heightAnchor constraintEqualToAnchor:daysBottomSpacerView.heightAnchor]
    ]];
}

- (void)layoutDaysDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *daysDigitsStackView = [self layoutDigitsStackViewInStackView:stackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:daysDigitsStackView];
    
    NSLayoutConstraint *daysHeightConstraint = [[daysDigitsStackView.heightAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:daysHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        daysHeightConstraint
    ]];
    
    UILabel *invisibleDaysColonLabel = [self layoutColonLabelInStackView:daysDigitsStackView];
    invisibleDaysColonLabel.alpha = 0.f;
    self.colonLabels = [self.colonLabels arrayByAddingObject:invisibleDaysColonLabel];
    
    UILabel *days1Label = [self layoutDigitLabelInStackView:daysDigitsStackView];
    self.days1Label = days1Label;
    
    UILabel *days0Label = [self layoutDigitLabelInStackView:daysDigitsStackView];
    self.days0Label = days0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [days1Label.widthAnchor constraintEqualToAnchor:days0Label.widthAnchor]
    ]];
}

- (void)layoutDaysTitleViewInStackView:(UIStackView *)stackView
{
    UIView *daysTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:daysTitleView];
        
    [NSLayoutConstraint activateConstraints:@[
        [daysTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *daysTitleLabel = [self layoutTimeUnitLabelInView:daysTitleView];
    daysTitleLabel.text = SRGLetterboxLocalizedString(@"Days", @"Short label for countdown display");
    self.daysTitleLabel = daysTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [daysTitleLabel.topAnchor constraintEqualToAnchor:daysTitleView.topAnchor],
        [daysTitleLabel.bottomAnchor constraintEqualToAnchor:daysTitleView.bottomAnchor],
        [daysTitleLabel.leadingAnchor constraintEqualToAnchor:self.days1Label.leadingAnchor],
        [daysTitleLabel.trailingAnchor constraintEqualToAnchor:self.days0Label.trailingAnchor]
    ]];
}

- (void)layoutHoursStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *hoursStackView = [self layoutTimeUnitStackViewInStackView:stackView];
    self.hoursStackView = hoursStackView;
    
    NSLayoutConstraint *hoursStackViewWidthConstraint = [[hoursStackView.widthAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:hoursStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        hoursStackViewWidthConstraint
    ]];
    
    UIView *hoursTopSpacerView = [self layoutFlexibleSpacerInStackView:hoursStackView];
    [self layoutHoursDigitsStackViewInStackView:hoursStackView];
    [self layoutHoursTitleViewInStackView:hoursStackView];
    UIView *hoursBottomSpacerView = [self layoutFlexibleSpacerInStackView:hoursStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [hoursTopSpacerView.heightAnchor constraintEqualToAnchor:hoursBottomSpacerView.heightAnchor]
    ]];
}

- (void)layoutHoursDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *hoursDigitsStackView = [self layoutDigitsStackViewInStackView:stackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:hoursDigitsStackView];
    
    NSLayoutConstraint *hoursHeightConstraint = [[hoursDigitsStackView.heightAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:hoursHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        hoursHeightConstraint
    ]];
    
    UILabel *hoursColonLabel = [self layoutColonLabelInStackView:hoursDigitsStackView];
    self.colonLabels = [self.colonLabels arrayByAddingObject:hoursColonLabel];
    self.hoursColonLabel = hoursColonLabel;
    
    UILabel *hours1Label = [self layoutDigitLabelInStackView:hoursDigitsStackView];
    self.hours1Label = hours1Label;
    
    UILabel *hours0Label = [self layoutDigitLabelInStackView:hoursDigitsStackView];
    self.hours0Label = hours0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [hours1Label.widthAnchor constraintEqualToAnchor:hours0Label.widthAnchor]
    ]];
}

- (void)layoutHoursTitleViewInStackView:(UIStackView *)stackView
{
    UIView *hoursTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:hoursTitleView];
    
    [NSLayoutConstraint activateConstraints:@[
        [hoursTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *hoursTitleLabel = [self layoutTimeUnitLabelInView:hoursTitleView];
    hoursTitleLabel.text = SRGLetterboxLocalizedString(@"Hours", @"Short label for countdown display");
    self.hoursTitleLabel = hoursTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [hoursTitleLabel.topAnchor constraintEqualToAnchor:hoursTitleView.topAnchor],
        [hoursTitleLabel.bottomAnchor constraintEqualToAnchor:hoursTitleView.bottomAnchor],
        [hoursTitleLabel.leadingAnchor constraintEqualToAnchor:self.hours1Label.leadingAnchor],
        [hoursTitleLabel.trailingAnchor constraintEqualToAnchor:self.hours0Label.trailingAnchor]
    ]];
}

- (void)layoutMinutesStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *minutesStackView = [self layoutTimeUnitStackViewInStackView:stackView];
    
    NSLayoutConstraint *minutesStackViewWidthConstraint = [[minutesStackView.widthAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:minutesStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        minutesStackViewWidthConstraint
    ]];
    
    UIView *minutesTopSpacerView = [self layoutFlexibleSpacerInStackView:minutesStackView];
    [self layoutMinutesDigitsStackViewInStackView:minutesStackView];
    [self layoutMinutesTitleViewInStackView:minutesStackView];
    UIView *minutesBottomSpacerView = [self layoutFlexibleSpacerInStackView:minutesStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [minutesTopSpacerView.heightAnchor constraintEqualToAnchor:minutesBottomSpacerView.heightAnchor]
    ]];
}

- (void)layoutMinutesDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *minutesDigitsStackView = [self layoutDigitsStackViewInStackView:stackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:minutesDigitsStackView];
    
    NSLayoutConstraint *minutesHeightConstraint = [[minutesDigitsStackView.heightAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:minutesHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        minutesHeightConstraint
    ]];
    
    UILabel *minutesColonLabel = [self layoutColonLabelInStackView:minutesDigitsStackView];
    self.colonLabels = [self.colonLabels arrayByAddingObject:minutesColonLabel];
    self.minutesColonLabel = minutesColonLabel;
    
    UILabel *minutes1Label = [self layoutDigitLabelInStackView:minutesDigitsStackView];
    self.minutes1Label = minutes1Label;
    
    UILabel *minutes0Label = [self layoutDigitLabelInStackView:minutesDigitsStackView];
    self.minutes0Label = minutes0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [minutes1Label.widthAnchor constraintEqualToAnchor:minutes0Label.widthAnchor]
    ]];
}

- (void)layoutMinutesTitleViewInStackView:(UIStackView *)stackView
{
    UIView *minutesTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:minutesTitleView];
    
    [NSLayoutConstraint activateConstraints:@[
        [minutesTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *minutesTitleLabel = [self layoutTimeUnitLabelInView:minutesTitleView];
    minutesTitleLabel.text = SRGLetterboxLocalizedString(@"Minutes", @"Short label for countdown display");
    self.minutesTitleLabel = minutesTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [minutesTitleLabel.topAnchor constraintEqualToAnchor:minutesTitleView.topAnchor],
        [minutesTitleLabel.bottomAnchor constraintEqualToAnchor:minutesTitleView.bottomAnchor],
        [minutesTitleLabel.leadingAnchor constraintEqualToAnchor:self.minutes1Label.leadingAnchor],
        [minutesTitleLabel.trailingAnchor constraintEqualToAnchor:self.minutes0Label.trailingAnchor]
    ]];
}

- (void)layoutSecondsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *secondsStackView = [self layoutTimeUnitStackViewInStackView:stackView];
    
    NSLayoutConstraint *secondsStackViewWidthConstraint = [[secondsStackView.widthAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:secondsStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        secondsStackViewWidthConstraint
    ]];
    
    self.secondsTopSpacerView = [self layoutFlexibleSpacerInStackView:secondsStackView];
    [self layoutSecondsDigitsStackViewInStackView:secondsStackView];
    [self layoutSecondsTitleViewInStackView:secondsStackView];
    self.secondsBottomSpacerView = [self layoutFlexibleSpacerInStackView:secondsStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.secondsTopSpacerView.heightAnchor constraintEqualToAnchor:self.secondsBottomSpacerView.heightAnchor]
    ]];
}

- (void)layoutSecondsDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *secondsDigitsStackView = [self layoutDigitsStackViewInStackView:stackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:secondsDigitsStackView];
    
    NSLayoutConstraint *secondsHeightConstraint = [[secondsDigitsStackView.heightAnchor constraintEqualToConstant:0.f /* set in -updateLayout */] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:secondsHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        secondsHeightConstraint
    ]];
    
    UILabel *secondsColonLabel = [self layoutColonLabelInStackView:secondsDigitsStackView];
    self.colonLabels = [self.colonLabels arrayByAddingObject:secondsColonLabel];
    
    UILabel *seconds1Label = [self layoutDigitLabelInStackView:secondsDigitsStackView];
    self.seconds1Label = seconds1Label;
    
    UILabel *seconds0Label = [self layoutDigitLabelInStackView:secondsDigitsStackView];
    self.seconds0Label = seconds0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [seconds1Label.widthAnchor constraintEqualToAnchor:seconds0Label.widthAnchor]
    ]];
}

- (void)layoutSecondsTitleViewInStackView:(UIStackView *)stackView
{
    UIView *secondsTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:secondsTitleView];
    
    [NSLayoutConstraint activateConstraints:@[
        [secondsTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *secondsTitleLabel = [self layoutTimeUnitLabelInView:secondsTitleView];
    secondsTitleLabel.text = SRGLetterboxLocalizedString(@"Seconds", @"Short label for countdown display");
    self.secondsTitleLabel = secondsTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [secondsTitleLabel.topAnchor constraintEqualToAnchor:secondsTitleView.topAnchor],
        [secondsTitleLabel.bottomAnchor constraintEqualToAnchor:secondsTitleView.bottomAnchor],
        [secondsTitleLabel.leadingAnchor constraintEqualToAnchor:self.seconds1Label.leadingAnchor],
        [secondsTitleLabel.trailingAnchor constraintEqualToAnchor:self.seconds0Label.trailingAnchor]
    ]];
}

- (void)layoutInvisibleColonInStackView:(UIStackView *)stackView
{
    UILabel *invisibleColonLabel = [self layoutColonLabelInStackView:stackView];
    invisibleColonLabel.alpha = 0.f;
}

- (void)layoutMessageLabelInView:(UIView *)view
{
    SRGPaddedLabel *messageLabel = [[SRGPaddedLabel alloc] init];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.adjustsFontSizeToFitWidth = YES;
    messageLabel.minimumScaleFactor = 0.6f;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.75f];
    messageLabel.horizontalMargin = 8.f;
    messageLabel.verticalMargin = 4.f;
    messageLabel.layer.masksToBounds = YES;
    [view addSubview:messageLabel];
    self.messageLabel = messageLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [messageLabel.centerXAnchor constraintEqualToAnchor:self.mainStackView.centerXAnchor],
        [messageLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.mainStackView.leadingAnchor constant:8.f],
        [messageLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.mainStackView.trailingAnchor constant:8.f],
        [messageLabel.topAnchor constraintEqualToAnchor:self.secondsBottomSpacerView.topAnchor constant:kMessageLabelTopSpace]
    ]];
}

- (void)layoutRemainingTimeLabelInView:(UIView *)view
{
    SRGPaddedLabel *remainingTimeLabel = [[SRGPaddedLabel alloc] init];
    remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    remainingTimeLabel.textAlignment = NSTextAlignmentCenter;
    remainingTimeLabel.adjustsFontSizeToFitWidth = YES;
    remainingTimeLabel.minimumScaleFactor = 0.6f;
    remainingTimeLabel.textColor = UIColor.whiteColor;
    remainingTimeLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.75f];
#if TARGET_OS_TV
    remainingTimeLabel.horizontalMargin = 30.f;
    remainingTimeLabel.verticalMargin = 12.f;
    remainingTimeLabel.layer.cornerRadius = 6.f;
#else
    remainingTimeLabel.horizontalMargin = 15.f;
    remainingTimeLabel.verticalMargin = 9.f;
    remainingTimeLabel.layer.cornerRadius = 3.f;
#endif
    remainingTimeLabel.layer.masksToBounds = YES;
    [view addSubview:remainingTimeLabel];
    self.remainingTimeLabel = remainingTimeLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [remainingTimeLabel.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [remainingTimeLabel.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
        [remainingTimeLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:view.leadingAnchor constant:8.f],
        [remainingTimeLabel.trailingAnchor constraintLessThanOrEqualToAnchor:view.trailingAnchor constant:8.f]
    ]];
}

- (void)layoutAccessibilityFrameInView:(UIView *)view
{
    UIView *accessibilityFrameView = [[UIView alloc] init];
    accessibilityFrameView.translatesAutoresizingMaskIntoConstraints = NO;
    [view insertSubview:accessibilityFrameView atIndex:0];
    self.accessibilityFrameView = accessibilityFrameView;
    
    [NSLayoutConstraint activateConstraints:@[
        [accessibilityFrameView.topAnchor constraintEqualToAnchor:self.secondsTopSpacerView.bottomAnchor],
        [accessibilityFrameView.bottomAnchor constraintEqualToAnchor:self.secondsBottomSpacerView.topAnchor],
        [accessibilityFrameView.leadingAnchor constraintEqualToAnchor:self.mainLeadingSpacerView.trailingAnchor],
        [accessibilityFrameView.trailingAnchor constraintEqualToAnchor:self.mainTrailingSpacerView.leadingAnchor]
    ]];
}

#pragma mark Getters and setters

- (void)setUpdateTimer:(NSTimer *)updateTimer
{
    [_updateTimer invalidate];
    _updateTimer = updateTimer;
}

- (NSTimeInterval)currentRemainingTimeInterval
{
    NSTimeInterval elapsedTimeInterval = [self.targetDate timeIntervalSinceDate:NSDate.date];
    return fmax(elapsedTimeInterval, 0.);
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        @weakify(self)
        self.updateTimer = [NSTimer srgletterbox_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            [self refresh];
        }];
        
        [self refresh];
    }
    else {
        self.updateTimer = nil;
    }
}

#if TARGET_OS_IOS

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    [self refresh];
}

#endif

#pragma mark UI

- (void)refresh
{
    NSTimeInterval currentRemainingTimeInterval = self.currentRemainingTimeInterval;
    NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(currentRemainingTimeInterval);
    
    // Large digit countdown construction
    NSInteger day1 = dateComponents.day / 10;
    if (day1 < SRGCountdownViewDaysLimit / 10) {
        self.days1Label.text = @(day1).stringValue;
        self.days0Label.text = @(dateComponents.day - day1 * 10).stringValue;
        
        NSInteger hours1 = dateComponents.hour / 10;
        self.hours1Label.text = @(hours1).stringValue;
        self.hours0Label.text = @(dateComponents.hour - hours1 * 10).stringValue;
        
        NSInteger minutes1 = dateComponents.minute / 10;
        self.minutes1Label.text = @(minutes1).stringValue;
        self.minutes0Label.text = @(dateComponents.minute - minutes1 * 10).stringValue;
        
        NSInteger seconds1 = dateComponents.second / 10;
        self.seconds1Label.text = @(seconds1).stringValue;
        self.seconds0Label.text = @(dateComponents.second - seconds1 * 10).stringValue;
    }
    else {
        self.days1Label.text = @"9";
        self.days0Label.text = @"9";
        
        self.hours1Label.text = @"2";
        self.hours0Label.text = @"3";
        
        self.minutes1Label.text = @"5";
        self.minutes0Label.text = @"9";
        
        self.seconds1Label.text = @"5";
        self.seconds0Label.text = @"9";
    }
    
    // Small coutndown label construction
    if (dateComponents.day >= SRGCountdownViewDaysLimit) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        self.remainingTimeLabel.text = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_dateComponentsFormatter stringFromTimeInterval:currentRemainingTimeInterval]].uppercaseString;
    }
    else if (dateComponents.day > 0) {
        self.remainingTimeLabel.text = [NSDateComponentsFormatter.srg_longDateComponentsFormatter stringFromDateComponents:dateComponents].uppercaseString;
    }
    else if (currentRemainingTimeInterval >= 60. * 60.) {
        self.remainingTimeLabel.text = [NSDateComponentsFormatter.srg_mediumDateComponentsFormatter stringFromDateComponents:dateComponents].uppercaseString;
    }
    else if (currentRemainingTimeInterval >= 0.) {
        self.remainingTimeLabel.text = [NSDateComponentsFormatter.srg_shortDateComponentsFormatter stringFromDateComponents:dateComponents].uppercaseString;
    }
    else {
        self.remainingTimeLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.").uppercaseString;
    }
    
    // The layout highly depends on the value to be displayed, update it at the same time
    [self updateLayout];
}

- (void)updateLayout
{
#if TARGET_OS_IOS
    BOOL isLarge = (CGRectGetWidth(self.frame) >= 668.f);
    
    CGFloat width = isLarge ? 88.f : 70.f;
    CGFloat height = isLarge ? 57.f : 45.f;
    
    CGFloat digitFontSize = isLarge ? 45.f : 36.f;
    CGFloat titleFontSize = isLarge ? 17.f : 13.f;
    CGFloat digitCornerRadius = isLarge ? 3.f : 2.f;
    
    CGFloat spacing = isLarge ? 3.f : 2.f;
#else
    CGFloat width = 155.f;
    CGFloat height = 100.f;
    
    CGFloat digitFontSize = 80.f;
    CGFloat titleFontSize = 28.f;
    CGFloat digitCornerRadius = 3.f;
    
    CGFloat spacing = 3.f;
#endif
    
    // Appearance
    [self.widthConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = width;
    }];
    
    [self.heightConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = height;
    }];
    
    self.days1Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.days0Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.daysTitleLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:titleFontSize];
    
    self.hours1Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.hours0Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.hoursTitleLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:titleFontSize];
    
    self.minutes1Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.minutes0Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.minutesTitleLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:titleFontSize];
    
    self.seconds1Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.seconds0Label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    self.secondsTitleLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:titleFontSize];
    
    [self.colonLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:digitFontSize];
    }];
    
    self.days1Label.layer.cornerRadius = digitCornerRadius;
    self.days0Label.layer.cornerRadius = digitCornerRadius;
    
    self.hours1Label.layer.cornerRadius = digitCornerRadius;
    self.hours0Label.layer.cornerRadius = digitCornerRadius;
    
    self.minutes1Label.layer.cornerRadius = digitCornerRadius;
    self.minutes0Label.layer.cornerRadius = digitCornerRadius;
    
    self.seconds1Label.layer.cornerRadius = digitCornerRadius;
    self.seconds0Label.layer.cornerRadius = digitCornerRadius;
    
    self.messageLabel.layer.cornerRadius = digitCornerRadius;
    
    [self.digitsStackViews enumerateObjectsUsingBlock:^(UIStackView * _Nonnull stackView, NSUInteger idx, BOOL * _Nonnull stop) {
        stackView.spacing = spacing;
    }];
    
    self.remainingTimeLabel.font = [SRGFont fontWithStyle:SRGFontStyleH4];
    self.messageLabel.font = [SRGFont fontWithStyle:SRGFontStyleH4];
    
    // Visibility
    NSTimeInterval currentRemainingTimeInterval = self.currentRemainingTimeInterval;
    NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(currentRemainingTimeInterval);
    if (dateComponents.day >= SRGCountdownViewDaysLimit) {
        self.remainingTimeLabel.hidden = NO;
        self.mainStackView.hidden = YES;
        self.messageLabel.hidden = YES;
    }
#if TARGET_OS_IOS
    else if (CGRectGetWidth(self.frame) < 300.f || CGRectGetHeight(self.frame) < 145.f) {
        self.remainingTimeLabel.hidden = NO;
        self.mainStackView.hidden = YES;
        self.messageLabel.hidden = YES;
    }
#endif
    else {
        self.remainingTimeLabel.hidden = YES;
        self.mainStackView.hidden = NO;
        
        self.messageLabel.hidden = (currentRemainingTimeInterval != 0);
        
        if (dateComponents.day == 0) {
            self.daysStackView.hidden = YES;
            self.hoursColonLabel.hidden = YES;
            
            if (dateComponents.hour == 0) {
                self.hoursStackView.hidden = YES;
                self.minutesColonLabel.hidden = YES;
            }
            else {
                self.hoursStackView.hidden = NO;
                self.minutesColonLabel.hidden = NO;
            }
        }
        else {
            self.daysStackView.hidden = NO;
            self.hoursColonLabel.hidden = NO;
            
            self.hoursStackView.hidden = NO;
            self.minutesColonLabel.hidden = NO;
        }
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (self.currentRemainingTimeInterval > 0) {
        return [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [NSDateComponentsFormatter.srg_accessibilityDateComponentsFormatter stringFromTimeInterval:self.currentRemainingTimeInterval]];
    }
    else {
        return SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
    }
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitUpdatesFrequently;
}

- (CGRect)accessibilityFrame
{
    return UIAccessibilityConvertFrameToScreenCoordinates(self.accessibilityFrameView.frame, self);
}

@end

NSDateComponents *SRGDateComponentsForTimeIntervalSinceNow(NSTimeInterval timeInterval)
{
    NSDate *nowDate = NSDate.date;
    return [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                           fromDate:nowDate
                                             toDate:[NSDate dateWithTimeInterval:timeInterval sinceDate:nowDate]
                                            options:0];
}
