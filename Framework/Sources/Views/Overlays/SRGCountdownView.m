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

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

NSInteger SRGCountdownViewDaysLimit = 100;

@interface SRGCountdownView ()

@property (nonatomic) IBOutletCollection(UIStackView) NSArray* digitStackViews;

@property (nonatomic, weak) IBOutlet UIStackView *daysStackView;

@property (nonatomic, weak) IBOutlet UILabel *days1Label;
@property (nonatomic, weak) IBOutlet UILabel *days0Label;
@property (nonatomic, weak) IBOutlet UILabel *daysTitleLabel;

@property (nonatomic, weak) IBOutlet UIStackView *hoursStackView;

@property (nonatomic, weak) IBOutlet UILabel *hoursColonLabel;
@property (nonatomic, weak) IBOutlet UILabel *hours1Label;
@property (nonatomic, weak) IBOutlet UILabel *hours0Label;
@property (nonatomic, weak) IBOutlet UILabel *hoursTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *minutesColonLabel;
@property (nonatomic, weak) IBOutlet UILabel *minutes1Label;
@property (nonatomic, weak) IBOutlet UILabel *minutes0Label;
@property (nonatomic, weak) IBOutlet UILabel *minutesTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *seconds1Label;
@property (nonatomic, weak) IBOutlet UILabel *seconds0Label;
@property (nonatomic, weak) IBOutlet UILabel *secondsTitleLabel;

@property (nonatomic) IBOutletCollection(UILabel) NSArray *colonLabels;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *widthConstraints;
@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *heightConstraints;

@property (nonatomic, weak) IBOutlet SRGPaddedLabel *messageLabel;

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

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.days1Label.layer.masksToBounds = YES;
    self.days0Label.layer.masksToBounds = YES;
    
    self.daysTitleLabel.text = SRGLetterboxLocalizedString(@"Days", @"Short label for countdown display");
    
    self.hours1Label.layer.masksToBounds = YES;
    self.hours0Label.layer.masksToBounds = YES;
    
    self.hoursTitleLabel.text = SRGLetterboxLocalizedString(@"Hours", @"Short label for countdown display");
    
    self.minutes1Label.layer.masksToBounds = YES;
    self.minutes0Label.layer.masksToBounds = YES;
    
    self.minutesTitleLabel.text = SRGLetterboxLocalizedString(@"Minutes", @"Short label for countdown display");
    
    self.seconds1Label.layer.masksToBounds = YES;
    self.seconds0Label.layer.masksToBounds = YES;
    
    self.secondsTitleLabel.text = SRGLetterboxLocalizedString(@"Seconds", @"Short label for countdown display");
    
    self.messageLabel.horizontalMargin = 5.f;
    self.messageLabel.verticalMargin = 2.f;
    self.messageLabel.layer.masksToBounds = YES;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        @weakify(self)
        self.updateTimer = [NSTimer srg_scheduledTimerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            [self refresh];
            [self updateLayout];
        }];
        
        [self refresh];
        [self updateLayout];
    }
    else {
        self.updateTimer = nil;
    }
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    [self updateLayout];
}

#pragma mark Getters and setters

- (void)setRemainingTimeInterval:(NSTimeInterval)remainingTimeInterval
{
    _remainingTimeInterval = MAX(remainingTimeInterval, 0);
    
    self.initialDate = NSDate.date;
    
    [self refresh];
    [self updateLayout];
}

#pragma mark UI

- (void)refresh
{
    NSTimeInterval elapsedTime = [NSDate.date timeIntervalSinceDate:self.initialDate];
    NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(fmax(self.remainingTimeInterval - elapsedTime, 0.));
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
    
    if (self.remainingTimeInterval == 0) {
        self.messageLabel.text = SRGLetterboxLocalizedString(@"Playback will begin shortly", @"Message displayed to inform that playback should start soon.");
    }
    else {
        self.messageLabel.text = nil;
    }
}

- (void)updateLayout
{
    BOOL isLarge = (CGRectGetWidth(self.frame) >= 668.f);
    
    [self.widthConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = isLarge ? 88.f : 70.f;
    }];
    
    [self.heightConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = isLarge ? 57.f : 45.f;
    }];
    
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
    
    [self.digitStackViews enumerateObjectsUsingBlock:^(UIStackView * _Nonnull stackView, NSUInteger idx, BOOL * _Nonnull stop) {
        stackView.spacing = isLarge ? 3.f : 2.f;
    }];
    
    self.messageLabel.font = [UIFont srg_mediumFontWithSize:titleSize];
    
    // Hide days / hours when not needed
    NSDateComponents *dateComponents = SRGDateComponentsForTimeIntervalSinceNow(self.remainingTimeInterval);
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

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (self.remainingTimeInterval > 0) {
        return [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Available in %@", @"Label to explain that a content will be available in X minutes / seconds."), [[NSDateComponentsFormatter srg_accessibilityDateComponentsFormatter] stringFromTimeInterval:self.remainingTimeInterval]];
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
