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
    static const CGFloat kTitleHeight = 40.f;
#else
    static const CGFloat kTitleHeight = 30.f;
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

- (void)createView
{
    [super createView];
    
    [self createMainStackViewInView:self];
    [self createMessageLabelInView:self];
    [self createRemainingTimeLabelInView:self];
    [self createAccessibilityFrameInView:self];
}

- (UIView *)createFlexibleSpacerInStackView:(UIStackView *)stackView
{
    UIView *spacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:spacerView];
    return spacerView;
}

- (void)createMainStackViewInView:(UIView *)view
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
    
    if (@available(iOS 11, *)) {
        [NSLayoutConstraint activateConstraints:@[
            [mainStackView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor],
            [mainStackView.bottomAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.bottomAnchor],
            [mainStackView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
            [mainStackView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor]
        ]];
    }
    else {
        [NSLayoutConstraint activateConstraints:@[
            [mainStackView.topAnchor constraintEqualToAnchor:view.topAnchor],
            [mainStackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
            [mainStackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
            [mainStackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
        ]];
    }
    
    self.mainLeadingSpacerView = [self createFlexibleSpacerInStackView:mainStackView];
    [self createDaysStackViewInStackView:mainStackView];
    [self createHoursStackViewInStackView:mainStackView];
    [self createMinutesStackViewInStackView:mainStackView];
    [self createSecondsStackViewInStackView:mainStackView];
    [self createInvisibleBalancingColonInStackView:mainStackView];
    self.mainTrailingSpacerView = [self createFlexibleSpacerInStackView:mainStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mainLeadingSpacerView.widthAnchor constraintEqualToAnchor:self.mainTrailingSpacerView.widthAnchor]
    ]];
}

- (void)createDaysStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *daysStackView = [[UIStackView alloc] init];
    daysStackView.axis = UILayoutConstraintAxisVertical;
    daysStackView.alignment = UIStackViewAlignmentFill;
    daysStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:daysStackView];
    self.daysStackView = daysStackView;
    
    NSLayoutConstraint *daysStackViewWidthConstraint = [[daysStackView.widthAnchor constraintEqualToConstant:0.f] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:daysStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        daysStackViewWidthConstraint
    ]];
    
    UIView *daysTopSpacerView = [self createFlexibleSpacerInStackView:daysStackView];
    [self createDaysDigitsStackViewInStackView:daysStackView];
    [self createDaysTitleViewInStackView:daysStackView];
    UIView *daysBottomSpacerView = [self createFlexibleSpacerInStackView:daysStackView];;
    
    [NSLayoutConstraint activateConstraints:@[
        [daysTopSpacerView.heightAnchor constraintEqualToAnchor:daysBottomSpacerView.heightAnchor]
    ]];
}

- (void)createDaysDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *daysDigitsStackView = [[UIStackView alloc] init];
    daysDigitsStackView.axis = UILayoutConstraintAxisHorizontal;
    daysDigitsStackView.alignment = UIStackViewAlignmentFill;
    daysDigitsStackView.distribution = UIStackViewDistributionFill;
    daysDigitsStackView.spacing = 2.f;
    [stackView addArrangedSubview:daysDigitsStackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:daysDigitsStackView];
    
    NSLayoutConstraint *daysHeightConstraint = [[daysDigitsStackView.heightAnchor constraintEqualToConstant:45.f] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:daysHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        daysHeightConstraint
    ]];
    
    UILabel *invisibleDaysColonLabel = [[UILabel alloc] init];
    invisibleDaysColonLabel.text = @":";
    invisibleDaysColonLabel.textAlignment = NSTextAlignmentCenter;
    invisibleDaysColonLabel.alpha = 0.f;
    [invisibleDaysColonLabel setContentHuggingPriority:252 forAxis:UILayoutConstraintAxisHorizontal];
    [daysDigitsStackView addArrangedSubview:invisibleDaysColonLabel];
    self.colonLabels = [self.colonLabels arrayByAddingObject:invisibleDaysColonLabel];
    
    UILabel *days1Label = [[UILabel alloc] init];
    days1Label.textColor = UIColor.whiteColor;
    days1Label.backgroundColor = UIColor.blackColor;
    days1Label.textAlignment = NSTextAlignmentCenter;
    days1Label.layer.masksToBounds = YES;
    [daysDigitsStackView addArrangedSubview:days1Label];
    self.days1Label = days1Label;
    
    UILabel *days0Label = [[UILabel alloc] init];
    days0Label.textColor = UIColor.whiteColor;
    days0Label.backgroundColor = UIColor.blackColor;
    days0Label.textAlignment = NSTextAlignmentCenter;
    days0Label.layer.masksToBounds = YES;
    [daysDigitsStackView addArrangedSubview:days0Label];
    self.days0Label = days0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [days1Label.widthAnchor constraintEqualToAnchor:days0Label.widthAnchor]
    ]];
}

- (void)createDaysTitleViewInStackView:(UIStackView *)stackView
{
    UIView *daysTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:daysTitleView];
        
    [NSLayoutConstraint activateConstraints:@[
        [daysTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *daysTitleLabel = [[UILabel alloc] init];
    daysTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    daysTitleLabel.text = SRGLetterboxLocalizedString(@"Days", @"Short label for countdown display");
    daysTitleLabel.textColor = UIColor.whiteColor;
    daysTitleLabel.textAlignment = NSTextAlignmentCenter;
    [daysTitleView addSubview:daysTitleLabel];
    self.daysTitleLabel = daysTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [daysTitleLabel.topAnchor constraintEqualToAnchor:daysTitleView.topAnchor],
        [daysTitleLabel.bottomAnchor constraintEqualToAnchor:daysTitleView.bottomAnchor],
        [daysTitleLabel.leadingAnchor constraintEqualToAnchor:self.days1Label.leadingAnchor],
        [daysTitleLabel.trailingAnchor constraintEqualToAnchor:self.days0Label.trailingAnchor]
    ]];
}

- (void)createHoursStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *hoursStackView = [[UIStackView alloc] init];
    hoursStackView.axis = UILayoutConstraintAxisVertical;
    hoursStackView.alignment = UIStackViewAlignmentFill;
    hoursStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:hoursStackView];
    self.hoursStackView = hoursStackView;
    
    NSLayoutConstraint *hoursStackViewWidthConstraint = [[hoursStackView.widthAnchor constraintEqualToConstant:0.f] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:hoursStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        hoursStackViewWidthConstraint
    ]];
    
    UIView *hoursTopSpacerView = [self createFlexibleSpacerInStackView:hoursStackView];
    [self createHoursDigitsStackViewInStackView:hoursStackView];
    [self createHoursTitleViewInStackView:hoursStackView];
    UIView *hoursBottomSpacerView = [self createFlexibleSpacerInStackView:hoursStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [hoursTopSpacerView.heightAnchor constraintEqualToAnchor:hoursBottomSpacerView.heightAnchor]
    ]];
}

- (void)createHoursDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *hoursDigitsStackView = [[UIStackView alloc] init];
    hoursDigitsStackView.axis = UILayoutConstraintAxisHorizontal;
    hoursDigitsStackView.alignment = UIStackViewAlignmentFill;
    hoursDigitsStackView.distribution = UIStackViewDistributionFill;
    hoursDigitsStackView.spacing = 2.f;
    [stackView addArrangedSubview:hoursDigitsStackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:hoursDigitsStackView];
    
    NSLayoutConstraint *hoursHeightConstraint = [[hoursDigitsStackView.heightAnchor constraintEqualToConstant:45.f] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:hoursHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        hoursHeightConstraint
    ]];
    
    UILabel *hoursColonLabel = [[UILabel alloc] init];
    hoursColonLabel.text = @":";
    hoursColonLabel.textAlignment = NSTextAlignmentCenter;
    hoursColonLabel.textColor = UIColor.whiteColor;
    [hoursColonLabel setContentHuggingPriority:252 forAxis:UILayoutConstraintAxisHorizontal];
    [hoursDigitsStackView addArrangedSubview:hoursColonLabel];
    self.colonLabels = [self.colonLabels arrayByAddingObject:hoursColonLabel];
    self.hoursColonLabel = hoursColonLabel;
    
    UILabel *hours1Label = [[UILabel alloc] init];
    hours1Label.textColor = UIColor.whiteColor;
    hours1Label.backgroundColor = UIColor.blackColor;
    hours1Label.textAlignment = NSTextAlignmentCenter;
    hours1Label.layer.masksToBounds = YES;
    [hoursDigitsStackView addArrangedSubview:hours1Label];
    self.hours1Label = hours1Label;
    
    UILabel *hours0Label = [[UILabel alloc] init];
    hours0Label.textColor = UIColor.whiteColor;
    hours0Label.backgroundColor = UIColor.blackColor;
    hours0Label.textAlignment = NSTextAlignmentCenter;
    hours0Label.layer.masksToBounds = YES;
    [hoursDigitsStackView addArrangedSubview:hours0Label];
    self.hours0Label = hours0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [hours1Label.widthAnchor constraintEqualToAnchor:hours0Label.widthAnchor]
    ]];
}

- (void)createHoursTitleViewInStackView:(UIStackView *)stackView
{
    UIView *hoursTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:hoursTitleView];
    
    [NSLayoutConstraint activateConstraints:@[
        [hoursTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *hoursTitleLabel = [[UILabel alloc] init];
    hoursTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    hoursTitleLabel.text = SRGLetterboxLocalizedString(@"Hours", @"Short label for countdown display");
    hoursTitleLabel.textColor = UIColor.whiteColor;
    hoursTitleLabel.textAlignment = NSTextAlignmentCenter;
    [hoursTitleView addSubview:hoursTitleLabel];
    self.hoursTitleLabel = hoursTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [hoursTitleLabel.topAnchor constraintEqualToAnchor:hoursTitleView.topAnchor],
        [hoursTitleLabel.bottomAnchor constraintEqualToAnchor:hoursTitleView.bottomAnchor],
        [hoursTitleLabel.leadingAnchor constraintEqualToAnchor:self.hours1Label.leadingAnchor],
        [hoursTitleLabel.trailingAnchor constraintEqualToAnchor:self.hours0Label.trailingAnchor]
    ]];
}

- (void)createMinutesStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *minutesStackView = [[UIStackView alloc] init];
    minutesStackView.axis = UILayoutConstraintAxisVertical;
    minutesStackView.alignment = UIStackViewAlignmentFill;
    minutesStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:minutesStackView];
    
    NSLayoutConstraint *minutesStackViewWidthConstraint = [[minutesStackView.widthAnchor constraintEqualToConstant:0.f] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:minutesStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        minutesStackViewWidthConstraint
    ]];
    
    UIView *minutesTopSpacerView = [self createFlexibleSpacerInStackView:minutesStackView];
    [self createMinutesDigitsStackViewInStackView:minutesStackView];
    [self createMinutesTitleViewInStackView:minutesStackView];
    UIView *minutesBottomSpacerView = [self createFlexibleSpacerInStackView:minutesStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [minutesTopSpacerView.heightAnchor constraintEqualToAnchor:minutesBottomSpacerView.heightAnchor]
    ]];
}

- (void)createMinutesDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *minutesDigitsStackView = [[UIStackView alloc] init];
    minutesDigitsStackView.axis = UILayoutConstraintAxisHorizontal;
    minutesDigitsStackView.alignment = UIStackViewAlignmentFill;
    minutesDigitsStackView.distribution = UIStackViewDistributionFill;
    minutesDigitsStackView.spacing = 2.f;
    [stackView addArrangedSubview:minutesDigitsStackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:minutesDigitsStackView];
    
    NSLayoutConstraint *minutesHeightConstraint = [[minutesDigitsStackView.heightAnchor constraintEqualToConstant:45.f] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:minutesHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        minutesHeightConstraint
    ]];
    
    UILabel *minutesColonLabel = [[UILabel alloc] init];
    minutesColonLabel.text = @":";
    minutesColonLabel.textAlignment = NSTextAlignmentCenter;
    minutesColonLabel.textColor = UIColor.whiteColor;
    [minutesColonLabel setContentHuggingPriority:252 forAxis:UILayoutConstraintAxisHorizontal];
    [minutesDigitsStackView addArrangedSubview:minutesColonLabel];
    self.colonLabels = [self.colonLabels arrayByAddingObject:minutesColonLabel];
    self.minutesColonLabel = minutesColonLabel;
    
    UILabel *minutes1Label = [[UILabel alloc] init];
    minutes1Label.textColor = UIColor.whiteColor;
    minutes1Label.backgroundColor = UIColor.blackColor;
    minutes1Label.textAlignment = NSTextAlignmentCenter;
    minutes1Label.layer.masksToBounds = YES;
    [minutesDigitsStackView addArrangedSubview:minutes1Label];
    self.minutes1Label = minutes1Label;
    
    UILabel *minutes0Label = [[UILabel alloc] init];
    minutes0Label.textColor = UIColor.whiteColor;
    minutes0Label.backgroundColor = UIColor.blackColor;
    minutes0Label.textAlignment = NSTextAlignmentCenter;
    minutes0Label.layer.masksToBounds = YES;
    [minutesDigitsStackView addArrangedSubview:minutes0Label];
    self.minutes0Label = minutes0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [minutes1Label.widthAnchor constraintEqualToAnchor:minutes0Label.widthAnchor]
    ]];
}

- (void)createMinutesTitleViewInStackView:(UIStackView *)stackView
{
    UIView *minutesTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:minutesTitleView];
    
    [NSLayoutConstraint activateConstraints:@[
        [minutesTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *minutesTitleLabel = [[UILabel alloc] init];
    minutesTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    minutesTitleLabel.text = SRGLetterboxLocalizedString(@"Minutes", @"Short label for countdown display");
    minutesTitleLabel.textColor = UIColor.whiteColor;
    minutesTitleLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addSubview:minutesTitleLabel];
    self.minutesTitleLabel = minutesTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [minutesTitleLabel.topAnchor constraintEqualToAnchor:minutesTitleView.topAnchor],
        [minutesTitleLabel.bottomAnchor constraintEqualToAnchor:minutesTitleView.bottomAnchor],
        [minutesTitleLabel.leadingAnchor constraintEqualToAnchor:self.minutes1Label.leadingAnchor],
        [minutesTitleLabel.trailingAnchor constraintEqualToAnchor:self.minutes0Label.trailingAnchor]
    ]];
}

- (void)createSecondsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *secondsStackView = [[UIStackView alloc] init];
    secondsStackView.axis = UILayoutConstraintAxisVertical;
    secondsStackView.alignment = UIStackViewAlignmentFill;
    secondsStackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:secondsStackView];
    
    NSLayoutConstraint *secondsStackViewWidthConstraint = [[secondsStackView.widthAnchor constraintEqualToConstant:0.f] srgletterbox_withPriority:999];
    self.widthConstraints = [self.widthConstraints arrayByAddingObject:secondsStackViewWidthConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        secondsStackViewWidthConstraint
    ]];
    
    self.secondsTopSpacerView = [self createFlexibleSpacerInStackView:secondsStackView];
    [self createSecondsDigitsStackViewInStackView:secondsStackView];
    [self createSecondsTitleViewInStackView:secondsStackView];
    self.secondsBottomSpacerView = [self createFlexibleSpacerInStackView:secondsStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.secondsTopSpacerView.heightAnchor constraintEqualToAnchor:self.secondsBottomSpacerView.heightAnchor]
    ]];
}

- (void)createSecondsDigitsStackViewInStackView:(UIStackView *)stackView
{
    UIStackView *secondsDigitsStackView = [[UIStackView alloc] init];
    secondsDigitsStackView.axis = UILayoutConstraintAxisHorizontal;
    secondsDigitsStackView.alignment = UIStackViewAlignmentFill;
    secondsDigitsStackView.distribution = UIStackViewDistributionFill;
    secondsDigitsStackView.spacing = 2.f;
    [stackView addArrangedSubview:secondsDigitsStackView];
    self.digitsStackViews = [self.digitsStackViews arrayByAddingObject:secondsDigitsStackView];
    
    NSLayoutConstraint *secondsHeightConstraint = [[secondsDigitsStackView.heightAnchor constraintEqualToConstant:45.f] srgletterbox_withPriority:999];
    self.heightConstraints = [self.heightConstraints arrayByAddingObject:secondsHeightConstraint];
    
    [NSLayoutConstraint activateConstraints:@[
        secondsHeightConstraint
    ]];
    
    UILabel *secondsColonLabel = [[UILabel alloc] init];
    secondsColonLabel.text = @":";
    secondsColonLabel.textAlignment = NSTextAlignmentCenter;
    secondsColonLabel.textColor = UIColor.whiteColor;
    [secondsColonLabel setContentHuggingPriority:252 forAxis:UILayoutConstraintAxisHorizontal];
    [secondsDigitsStackView addArrangedSubview:secondsColonLabel];
    self.colonLabels = [self.colonLabels arrayByAddingObject:secondsColonLabel];
    
    UILabel *seconds1Label = [[UILabel alloc] init];
    seconds1Label.textColor = UIColor.whiteColor;
    seconds1Label.backgroundColor = UIColor.blackColor;
    seconds1Label.textAlignment = NSTextAlignmentCenter;
    seconds1Label.layer.masksToBounds = YES;
    [secondsDigitsStackView addArrangedSubview:seconds1Label];
    self.seconds1Label = seconds1Label;
    
    UILabel *seconds0Label = [[UILabel alloc] init];
    seconds0Label.textColor = UIColor.whiteColor;
    seconds0Label.backgroundColor = UIColor.blackColor;
    seconds0Label.textAlignment = NSTextAlignmentCenter;
    seconds0Label.layer.masksToBounds = YES;
    [secondsDigitsStackView addArrangedSubview:seconds0Label];
    self.seconds0Label = seconds0Label;
    
    [NSLayoutConstraint activateConstraints:@[
        [seconds1Label.widthAnchor constraintEqualToAnchor:seconds0Label.widthAnchor]
    ]];
}

- (void)createSecondsTitleViewInStackView:(UIStackView *)stackView
{
    UIView *secondsTitleView = [[UIView alloc] init];
    [stackView addArrangedSubview:secondsTitleView];
    
    [NSLayoutConstraint activateConstraints:@[
        [secondsTitleView.heightAnchor constraintEqualToConstant:kTitleHeight]
    ]];
    
    UILabel *secondsTitleLabel = [[UILabel alloc] init];
    secondsTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    secondsTitleLabel.text = SRGLetterboxLocalizedString(@"Seconds", @"Short label for countdown display");
    secondsTitleLabel.textColor = UIColor.whiteColor;
    secondsTitleLabel.textAlignment = NSTextAlignmentCenter;
    [stackView addSubview:secondsTitleLabel];
    self.secondsTitleLabel = secondsTitleLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [secondsTitleLabel.topAnchor constraintEqualToAnchor:secondsTitleView.topAnchor],
        [secondsTitleLabel.bottomAnchor constraintEqualToAnchor:secondsTitleView.bottomAnchor],
        [secondsTitleLabel.leadingAnchor constraintEqualToAnchor:self.seconds1Label.leadingAnchor],
        [secondsTitleLabel.trailingAnchor constraintEqualToAnchor:self.seconds0Label.trailingAnchor]
    ]];
}

- (void)createInvisibleBalancingColonInStackView:(UIStackView *)stackView
{
    UILabel *invisibleBalancingColonLabel = [[UILabel alloc] init];
    invisibleBalancingColonLabel.text = @":";
    invisibleBalancingColonLabel.textAlignment = NSTextAlignmentCenter;
    invisibleBalancingColonLabel.alpha = 0.f;
    [invisibleBalancingColonLabel setContentHuggingPriority:252 forAxis:UILayoutConstraintAxisHorizontal];
    [stackView addArrangedSubview:invisibleBalancingColonLabel];
    self.colonLabels = [self.colonLabels arrayByAddingObject:invisibleBalancingColonLabel];
}

- (void)createMessageLabelInView:(UIView *)view
{
    SRGPaddedLabel *messageLabel = [[SRGPaddedLabel alloc] init];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.textColor = UIColor.whiteColor;
    messageLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.75f];
    messageLabel.horizontalMargin = 8.f;
    messageLabel.verticalMargin = 4.f;
    messageLabel.layer.masksToBounds = YES;
    [view addSubview:messageLabel];
    self.messageLabel = messageLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [messageLabel.centerXAnchor constraintEqualToAnchor:self.mainStackView.centerXAnchor],
        [messageLabel.topAnchor constraintEqualToAnchor:self.secondsBottomSpacerView.bottomAnchor constant:10.f]
    ]];
}

- (void)createRemainingTimeLabelInView:(UIView *)view
{
    SRGPaddedLabel *remainingTimeLabel = [[SRGPaddedLabel alloc] init];
    remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    remainingTimeLabel.textAlignment = NSTextAlignmentCenter;
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
}

- (void)createAccessibilityFrameInView:(UIView *)view
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
    
    [NSLayoutConstraint activateConstraints:@[
        [self.remainingTimeLabel.centerXAnchor constraintEqualToAnchor:accessibilityFrameView.centerXAnchor],
        [self.remainingTimeLabel.centerYAnchor constraintEqualToAnchor:accessibilityFrameView.centerYAnchor]
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
    
    CGFloat digitFontSize = 65.f;
    CGFloat titleFontSize = 35.f;
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
    
    self.days1Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.days0Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.daysTitleLabel.font = [UIFont srg_mediumFontWithSize:titleFontSize];
    
    self.hours1Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.hours0Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.hoursTitleLabel.font = [UIFont srg_mediumFontWithSize:titleFontSize];
    
    self.minutes1Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.minutes0Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.minutesTitleLabel.font = [UIFont srg_mediumFontWithSize:titleFontSize];
    
    self.seconds1Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.seconds0Label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
    self.secondsTitleLabel.font = [UIFont srg_mediumFontWithSize:titleFontSize];
    
    [self.colonLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.font = [UIFont srg_mediumFontWithSize:digitFontSize];
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
    
#if TARGET_OS_TV
    self.remainingTimeLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleHeadline];
    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleHeadline];
#else
    self.remainingTimeLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.messageLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
#endif
    
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
