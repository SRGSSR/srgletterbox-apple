//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGLetterboxTimeSlider.h"

#import "UIColor+SRGLetterbox.h"

@import libextobjc;
@import SRGAppearance;

static void commonInit(SRGLetterboxTimeSlider *self);

@implementation SRGLetterboxTimeSlider

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
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

- (void)setValue:(float)value
{
    super.value = value;
    
    [self updateLayoutForValue:value];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateLayoutForValue:self.value];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return (self.alpha != 0);
}

#pragma mark Layout

- (void)updateLayoutForValue:(float)value
{
    CGRect trackFrame = [super trackRectForBounds:self.bounds];
    CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:value];
    
    static const CGFloat kHorizontalMargin = 5.f;
    static const CGFloat kVerticalMargin = 3.f;
    static const CGFloat kBubbleDistance = 6.f;
    
    if (self.valueLabel.text.length != 0) {
        self.valueLabel.hidden = NO;
        
        CGSize intrinsicContentSize = self.valueLabel.intrinsicContentSize;
        CGFloat width = intrinsicContentSize.width + 2 * kHorizontalMargin;
        CGFloat height = intrinsicContentSize.height + 2 * kVerticalMargin;
        self.valueLabel.frame = CGRectMake(fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetWidth(self.bounds) - width), 0.f),
                                           CGRectGetMinY(thumbRect) - height - kBubbleDistance,
                                           fminf(width, CGRectGetWidth(self.bounds)),
                                           height);
    }
    else {
        self.valueLabel.hidden = YES;
    }
    
    self.valueLabel.backgroundColor = self.live ? UIColor.srg_lightRedColor : UIColor.srg_gray23Color;
}

@end

static void commonInit(SRGLetterboxTimeSlider *self)
{
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    valueLabel.textColor = UIColor.whiteColor;
    valueLabel.layer.masksToBounds = YES;
    valueLabel.layer.cornerRadius = 3.f;
    valueLabel.isAccessibilityElement = NO;
    [self addSubview:valueLabel];
    self.valueLabel = valueLabel;
    
    [self updateLayoutForValue:self.value];
}

#endif
