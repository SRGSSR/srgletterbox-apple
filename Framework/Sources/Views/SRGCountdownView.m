//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGCountdownView.h"

#import "NSBundle+SRGLetterbox.h"

#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

static void commonInit(SRGCountdownView *self);

@interface SRGCountdownView ()

@property (nonatomic, weak) IBOutlet UILabel *days1Label;
@property (nonatomic, weak) IBOutlet UILabel *days0Label;
@property (nonatomic, weak) IBOutlet UILabel *daysTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *hours1Label;
@property (nonatomic, weak) IBOutlet UILabel *hours0Label;
@property (nonatomic, weak) IBOutlet UILabel *hoursTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *minutes1Label;
@property (nonatomic, weak) IBOutlet UILabel *minutes0Label;
@property (nonatomic, weak) IBOutlet UILabel *minutesTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *seconds1Label;
@property (nonatomic, weak) IBOutlet UILabel *seconds0Label;
@property (nonatomic, weak) IBOutlet UILabel *secondsTitleLabel;

@property (nonatomic) IBOutletCollection(UILabel) NSArray *colonLabels;

@end

@implementation SRGCountdownView

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

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateFonts];
        [self reloadData];
    }
}

#pragma mark Getters and setters

- (void)setRemainingTimeInterval:(NSTimeInterval)remainingTimeInterval
{
    _remainingTimeInterval = remainingTimeInterval;
    
    [self reloadData];
}

#pragma mark UI

- (void)reloadData
{
    NSDate *nowDate = NSDate.date;
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                                       fromDate:nowDate
                                                                         toDate:[NSDate dateWithTimeInterval:self.remainingTimeInterval sinceDate:nowDate]
                                                                        options:0];
    
    // TODO: What to do if > 99 days? < 0?
    
    NSInteger day1 = dateComponents.day / 10;
    self.days1Label.text = @(day1).stringValue;
    self.days0Label.text = @(dateComponents.day - 10 * day1).stringValue;
    
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

- (void)updateFonts
{
    self.days1Label.font = [UIFont srg_boldFontWithSize:self.days1Label.font.pointSize];
    self.days0Label.font = [UIFont srg_boldFontWithSize:self.days0Label.font.pointSize];
    self.daysTitleLabel.font = [UIFont srg_boldFontWithSize:self.daysTitleLabel.font.pointSize];
    
    self.hours1Label.font = [UIFont srg_boldFontWithSize:self.hours1Label.font.pointSize];
    self.hours0Label.font = [UIFont srg_boldFontWithSize:self.hours0Label.font.pointSize];
    self.hoursTitleLabel.font = [UIFont srg_boldFontWithSize:self.hoursTitleLabel.font.pointSize];
    
    self.minutes1Label.font = [UIFont srg_boldFontWithSize:self.minutes1Label.font.pointSize];
    self.minutes0Label.font = [UIFont srg_boldFontWithSize:self.minutes0Label.font.pointSize];
    self.minutesTitleLabel.font = [UIFont srg_boldFontWithSize:self.minutesTitleLabel.font.pointSize];
    
    self.seconds1Label.font = [UIFont srg_boldFontWithSize:self.seconds1Label.font.pointSize];
    self.seconds0Label.font = [UIFont srg_boldFontWithSize:self.seconds0Label.font.pointSize];
    self.secondsTitleLabel.font = [UIFont srg_boldFontWithSize:self.secondsTitleLabel.font.pointSize];
    
    [self.colonLabels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.font = [UIFont srg_boldFontWithSize:self.seconds0Label.font.pointSize];
    }];
}

@end

static void commonInit(SRGCountdownView *self)
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
