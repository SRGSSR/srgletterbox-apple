//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGCountdownView.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGPaddedLabel.h"
#import "SRGStackView.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

static const NSInteger SRGCountdownViewDaysLimit = 100;

@interface SRGCountdownView ()

@property (nonatomic, readonly) NSTimeInterval currentRemainingTimeInterval;

@property (nonatomic, weak) IBOutlet SRGStackView *remainingTimeStackView;

@property (nonatomic) NSArray<SRGStackView *>* digitStackViews;

@property (nonatomic, weak) SRGStackView *daysStackView;

@property (nonatomic, weak) UILabel *days1Label;
@property (nonatomic, weak) UILabel *days0Label;
@property (nonatomic, weak) UILabel *daysTitleLabel;

@property (nonatomic, weak) SRGStackView *hoursStackView;

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

@property (nonatomic) NSArray<UILabel *> *colonLabels;

@property (nonatomic, weak) IBOutlet SRGPaddedLabel *messageLabel;
@property (nonatomic, weak) IBOutlet SRGPaddedLabel *remainingTimeLabel;

@property (nonatomic, weak) IBOutlet UIView *accessibilityFrameView;

@property (nonatomic) NSDate *initialDate;
@property (nonatomic) NSTimer *updateTimer;

@end

@implementation SRGCountdownView

#pragma mark Getters and setters

- (void)setUpdateTimer:(NSTimer *)updateTimer
{
    [_updateTimer invalidate];
    _updateTimer = updateTimer;
}

- (NSTimeInterval)currentRemainingTimeInterval
{
    NSTimeInterval elapsedTimeInterval = [NSDate.date timeIntervalSinceDate:self.initialDate];
    return fmax(self.remainingTimeInterval - elapsedTimeInterval, 0.);
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.remainingTimeStackView.direction = SRGStackViewDirectionHorizontal;
    self.remainingTimeStackView.spacing = 3.f;
    
    NSMutableArray<SRGStackView *> *digitsStackViews = [NSMutableArray array];
    NSMutableArray<UILabel *> *colonLabels = [NSMutableArray array];
    
    // Header
    
    UIView *spacerView1 = [[UIView alloc] init];
    [self.remainingTimeStackView addSubview:spacerView1];
    
    // Days
    
    SRGStackView *daysStackView = [[SRGStackView alloc] init];
    [self.remainingTimeStackView addSubview:daysStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 70.f;
    }];
    self.daysStackView = daysStackView;
    
    UIView *daysSpacerView1 = [[UIView alloc] init];
    [daysStackView addSubview:daysSpacerView1];
    
    SRGStackView *daysDigitsStackView = [[SRGStackView alloc] init];
    daysDigitsStackView.direction = SRGStackViewDirectionHorizontal;
    daysDigitsStackView.spacing = 2.f;
    [daysStackView addSubview:daysDigitsStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 45.f;
    }];
    [digitsStackViews addObject:daysDigitsStackView];
    
    UILabel *daysColonLabel = [[UILabel alloc] init];
    daysColonLabel.text = @":";
    daysColonLabel.textAlignment = NSTextAlignmentCenter;
    daysColonLabel.alpha = 0.f;
    daysColonLabel.font = [UIFont systemFontOfSize:36.f];
    [daysDigitsStackView addSubview:daysColonLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    [colonLabels addObject:daysColonLabel];
    
    UILabel *days1Label = [[UILabel alloc] init];
    days1Label.textAlignment = NSTextAlignmentCenter;
    days1Label.textColor = UIColor.whiteColor;
    days1Label.backgroundColor = UIColor.blackColor;
    days1Label.layer.masksToBounds = YES;
    [daysDigitsStackView addSubview:days1Label];
    self.days1Label = days1Label;
    
    UILabel *days0Label = [[UILabel alloc] init];
    days0Label.textAlignment = NSTextAlignmentCenter;
    days0Label.textColor = UIColor.whiteColor;
    days0Label.backgroundColor = UIColor.blackColor;
    days0Label.layer.masksToBounds = YES;
    [daysDigitsStackView addSubview:days0Label];
    self.days0Label = days0Label;
    
    UILabel *daysTitleLabel = [[UILabel alloc] init];
    daysTitleLabel.text = SRGLetterboxLocalizedString(@"Days", @"Short label for countdown display");
    daysTitleLabel.textAlignment = NSTextAlignmentCenter;
    daysTitleLabel.textColor = UIColor.whiteColor;
    [daysStackView addSubview:daysTitleLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    self.daysTitleLabel = daysTitleLabel;
    
    UIView *daysSpacerView2 = [[UIView alloc] init];
    [daysStackView addSubview:daysSpacerView2];
    
    // Hours
    
    SRGStackView *hoursStackView = [[SRGStackView alloc] init];
    [self.remainingTimeStackView addSubview:hoursStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 70.f;
    }];
    self.hoursStackView = hoursStackView;
    
    UIView *hoursSpacerView1 = [[UIView alloc] init];
    [hoursStackView addSubview:hoursSpacerView1];
    
    SRGStackView *hoursDigitsStackView = [[SRGStackView alloc] init];
    hoursDigitsStackView.direction = SRGStackViewDirectionHorizontal;
    hoursDigitsStackView.spacing = 2.f;
    [hoursStackView addSubview:hoursDigitsStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 45.f;
    }];
    [digitsStackViews addObject:hoursStackView];
    
    UILabel *hoursColonLabel = [[UILabel alloc] init];
    hoursColonLabel.text = @":";
    hoursColonLabel.textAlignment = NSTextAlignmentCenter;
    hoursColonLabel.textColor = UIColor.whiteColor;
    hoursColonLabel.font = [UIFont systemFontOfSize:36.f];
    [hoursDigitsStackView addSubview:hoursColonLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    self.hoursColonLabel = hoursColonLabel;
    [colonLabels addObject:hoursColonLabel];
    
    UILabel *hours1Label = [[UILabel alloc] init];
    hours1Label.textAlignment = NSTextAlignmentCenter;
    hours1Label.textColor = UIColor.whiteColor;
    hours1Label.backgroundColor = UIColor.blackColor;
    hours1Label.layer.masksToBounds = YES;
    [hoursDigitsStackView addSubview:hours1Label];
    self.hours1Label = hours1Label;
    
    UILabel *hours0Label = [[UILabel alloc] init];
    hours0Label.textAlignment = NSTextAlignmentCenter;
    hours0Label.textColor = UIColor.whiteColor;
    hours0Label.backgroundColor = UIColor.blackColor;
    hours0Label.layer.masksToBounds = YES;
    [hoursDigitsStackView addSubview:hours0Label];
    self.hours0Label = hours0Label;
    
    UILabel *hoursTitleLabel = [[UILabel alloc] init];
    hoursTitleLabel.text = SRGLetterboxLocalizedString(@"Hours", @"Short label for countdown display");
    hoursTitleLabel.textAlignment = NSTextAlignmentCenter;
    hoursTitleLabel.textColor = UIColor.whiteColor;
    [hoursStackView addSubview:hoursTitleLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    self.hoursTitleLabel = hoursTitleLabel;
    
    UIView *hoursSpacerView2 = [[UIView alloc] init];
    [hoursStackView addSubview:hoursSpacerView2];
    
    // Minutes
    
    SRGStackView *minutesStackView = [[SRGStackView alloc] init];
    [self.remainingTimeStackView addSubview:minutesStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 70.f;
    }];
    
    UIView *minutesSpacerView1 = [[UIView alloc] init];
    [minutesStackView addSubview:minutesSpacerView1];
    
    SRGStackView *minutesDigitsStackView = [[SRGStackView alloc] init];
    minutesDigitsStackView.direction = SRGStackViewDirectionHorizontal;
    minutesDigitsStackView.spacing = 2.f;
    [minutesStackView addSubview:minutesDigitsStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 45.f;
    }];
    [digitsStackViews addObject:minutesDigitsStackView];
    
    UILabel *minutesColonLabel = [[UILabel alloc] init];
    minutesColonLabel.text = @":";
    minutesColonLabel.textAlignment = NSTextAlignmentCenter;
    minutesColonLabel.textColor = UIColor.whiteColor;
    minutesColonLabel.font = [UIFont systemFontOfSize:36.f];
    [minutesDigitsStackView addSubview:minutesColonLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    self.minutesColonLabel = minutesColonLabel;
    [colonLabels addObject:minutesColonLabel];
    
    UILabel *minutes1Label = [[UILabel alloc] init];
    minutes1Label.textAlignment = NSTextAlignmentCenter;
    minutes1Label.textColor = UIColor.whiteColor;
    minutes1Label.backgroundColor = UIColor.blackColor;
    minutes1Label.layer.masksToBounds = YES;
    [minutesDigitsStackView addSubview:minutes1Label];
    self.minutes1Label = minutes1Label;
    
    UILabel *minutes0Label = [[UILabel alloc] init];
    minutes0Label.textAlignment = NSTextAlignmentCenter;
    minutes0Label.textColor = UIColor.whiteColor;
    minutes0Label.backgroundColor = UIColor.blackColor;
    minutes0Label.layer.masksToBounds = YES;
    [minutesDigitsStackView addSubview:minutes0Label];
    self.minutes0Label = minutes0Label;
    
    UILabel *minutesTitleLabel = [[UILabel alloc] init];
    minutesTitleLabel.textAlignment = NSTextAlignmentCenter;
    minutesTitleLabel.textColor = UIColor.whiteColor;
    minutesTitleLabel.text = SRGLetterboxLocalizedString(@"Minutes", @"Short label for countdown display");
    [minutesStackView addSubview:minutesTitleLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    self.minutesTitleLabel = minutesTitleLabel;
    
    UIView *minutesSpacerView2 = [[UIView alloc] init];
    [minutesStackView addSubview:minutesSpacerView2];
    
    // Seconds
    
    SRGStackView *secondsStackView = [[SRGStackView alloc] init];
    [self.remainingTimeStackView addSubview:secondsStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 70.f;
    }];
    
    UIView *secondsSpacerView1 = [[UIView alloc] init];
    [secondsStackView addSubview:secondsSpacerView1];
    
    SRGStackView *secondsDigitsStackView = [[SRGStackView alloc] init];
    secondsDigitsStackView.direction = SRGStackViewDirectionHorizontal;
    secondsDigitsStackView.spacing = 2.f;
    [secondsStackView addSubview:secondsDigitsStackView withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 45.f;
    }];
    [digitsStackViews addObject:secondsDigitsStackView];
    
    UILabel *secondsColonLabel = [[UILabel alloc] init];
    secondsColonLabel.text = @":";
    secondsColonLabel.textAlignment = NSTextAlignmentCenter;
    secondsColonLabel.textColor = UIColor.whiteColor;
    secondsColonLabel.font = [UIFont systemFontOfSize:36.f];
    [secondsDigitsStackView addSubview:secondsColonLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    [colonLabels addObject:secondsColonLabel];
    
    UILabel *seconds1Label = [[UILabel alloc] init];
    seconds1Label.textAlignment = NSTextAlignmentCenter;
    seconds1Label.textColor = UIColor.whiteColor;
    seconds1Label.backgroundColor = UIColor.blackColor;
    seconds1Label.layer.masksToBounds = YES;
    [secondsDigitsStackView addSubview:seconds1Label];
    self.seconds1Label = seconds1Label;
    
    UILabel *seconds0Label = [[UILabel alloc] init];
    seconds0Label.textAlignment = NSTextAlignmentCenter;
    seconds0Label.textColor = UIColor.whiteColor;
    seconds0Label.backgroundColor = UIColor.blackColor;
    seconds0Label.layer.masksToBounds = YES;
    [secondsDigitsStackView addSubview:seconds0Label];
    self.seconds0Label = seconds0Label;
    
    UILabel *secondsTitleLabel = [[UILabel alloc] init];
    secondsTitleLabel.textAlignment = NSTextAlignmentCenter;
    secondsTitleLabel.textColor = UIColor.whiteColor;
    secondsTitleLabel.text = SRGLetterboxLocalizedString(@"Seconds", @"Short label for countdown display");
    [secondsStackView addSubview:secondsTitleLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    self.secondsTitleLabel = secondsTitleLabel;
    
    UIView *secondsSpacerView2 = [[UIView alloc] init];
    [secondsStackView addSubview:secondsSpacerView2];
    
    // Footer
    
    UILabel *trailingColonLabel = [[UILabel alloc] init];
    trailingColonLabel.text = @":";
    trailingColonLabel.alpha = 0.f;
    trailingColonLabel.font = [UIFont systemFontOfSize:36.f];
    [self.remainingTimeStackView addSubview:trailingColonLabel withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.hugging = 251;
    }];
    [colonLabels addObject:trailingColonLabel];
    
    UIView *spacerView2 = [[UIView alloc] init];
    [self.remainingTimeStackView addSubview:spacerView2];
    
    // Other
    self.digitStackViews = [digitsStackViews copy];
    
    self.messageLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
    self.messageLabel.horizontalMargin = 5.f;
    self.messageLabel.verticalMargin = 2.f;
    self.messageLabel.layer.masksToBounds = YES;
    
    self.remainingTimeLabel.horizontalMargin = 5.f;
    self.remainingTimeLabel.verticalMargin = 2.f;
    self.remainingTimeLabel.layer.masksToBounds = YES;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        @weakify(self)
        self.updateTimer = [NSTimer srg_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            [self refresh];
        }];
        
        [self refresh];
    }
    else {
        self.updateTimer = nil;
    }
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    [self refresh];
}

#pragma mark Getters and setters

- (void)setRemainingTimeInterval:(NSTimeInterval)remainingTimeInterval
{
    _remainingTimeInterval = MAX(remainingTimeInterval, 0);
    
    self.initialDate = NSDate.date;
    
    [self refresh];
}

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
        self.remainingTimeLabel.text = [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [s_dateComponentsFormatter stringFromTimeInterval:currentRemainingTimeInterval]];
    }
    else if (dateComponents.day > 0) {
        self.remainingTimeLabel.text = [[NSDateComponentsFormatter srg_longDateComponentsFormatter] stringFromDateComponents:dateComponents];
    }
    else if (currentRemainingTimeInterval >= 60. * 60.) {
        self.remainingTimeLabel.text = [[NSDateComponentsFormatter srg_mediumDateComponentsFormatter] stringFromDateComponents:dateComponents];
    }
    else if (currentRemainingTimeInterval >= 0.) {
        self.remainingTimeLabel.text = [[NSDateComponentsFormatter srg_shortDateComponentsFormatter] stringFromDateComponents:dateComponents];
    }
    else {
        self.remainingTimeLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
    }
    
    // The layout highly depends on the value to be displayed, update it at the same time
    [self updateLayout];
}

- (void)updateLayout
{
    // FIXME: Does not work anymore. The stack needs a mechanism for attributes updates
    BOOL isLarge = (CGRectGetWidth(self.frame) >= 668.f);
    
    // Appearance
#if 0
    [self.widthConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = isLarge ? 88.f : 70.f;
    }];
    
    [self.heightConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = isLarge ? 57.f : 45.f;
    }];
#endif
    
    CGFloat digitSize = isLarge ? 45.f : 36.f;
    CGFloat titleSize = isLarge ? 17.f : 13.f;
    
    self.days1Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.days0Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.daysTitleLabel.font = [UIFont srg_mediumFontWithSize:titleSize];
    
    self.hours1Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.hours0Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.hoursTitleLabel.font = [UIFont srg_mediumFontWithSize:titleSize];
    
    self.minutes1Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.minutes0Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.minutesTitleLabel.font = [UIFont srg_mediumFontWithSize:titleSize];
    
    self.seconds1Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.seconds0Label.font = [UIFont srg_mediumFontWithSize:digitSize];
    self.secondsTitleLabel.font = [UIFont srg_mediumFontWithSize:titleSize];
    
    [self.colonLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.font = [UIFont srg_mediumFontWithSize:digitSize];
    }];
    
    CGFloat digitCornerRadius = isLarge ? 3.f : 2.f;
    
    self.days1Label.layer.cornerRadius = digitCornerRadius;
    self.days0Label.layer.cornerRadius = digitCornerRadius;
    
    self.hours1Label.layer.cornerRadius = digitCornerRadius;
    self.hours0Label.layer.cornerRadius = digitCornerRadius;
    
    self.minutes1Label.layer.cornerRadius = digitCornerRadius;
    self.minutes0Label.layer.cornerRadius = digitCornerRadius;
    
    self.seconds1Label.layer.cornerRadius = digitCornerRadius;
    self.seconds0Label.layer.cornerRadius = digitCornerRadius;
    
    self.messageLabel.layer.cornerRadius = digitCornerRadius;
    
    [self.digitStackViews enumerateObjectsUsingBlock:^(SRGStackView * _Nonnull stackView, NSUInteger idx, BOOL * _Nonnull stop) {
        stackView.spacing = isLarge ? 3.f : 2.f;
    }];
    
    self.messageLabel.font = [UIFont srg_mediumFontWithSize:titleSize];
    
    // Visibility
    NSTimeInterval currentRemainingTimeInterval = self.currentRemainingTimeInterval;
    NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(currentRemainingTimeInterval);
    if (dateComponents.day >= SRGCountdownViewDaysLimit) {
        self.remainingTimeLabel.hidden = NO;
        self.remainingTimeStackView.hidden = YES;
        self.messageLabel.hidden = YES;
    }
    else if (CGRectGetWidth(self.frame) < 300.f || CGRectGetHeight(self.frame) < 145.f) {
        self.remainingTimeLabel.hidden = NO;
        self.remainingTimeStackView.hidden = YES;
        self.messageLabel.hidden = YES;
    }
    else {
        self.remainingTimeLabel.hidden = YES;
        self.remainingTimeStackView.hidden = NO;
        
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
        return [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [[NSDateComponentsFormatter srg_accessibilityDateComponentsFormatter] stringFromTimeInterval:self.currentRemainingTimeInterval]];
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
