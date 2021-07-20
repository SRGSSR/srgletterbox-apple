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

@interface SRGLetterboxTimeSlider ()

@property (nonatomic, weak) CAShapeLayer *tipLayer;

@end

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
        self.tipLayer.hidden = NO;
        
        CGSize intrinsicContentSize = self.valueLabel.intrinsicContentSize;
        CGFloat width = intrinsicContentSize.width + 2 * kHorizontalMargin;
        CGFloat height = intrinsicContentSize.height + 2 * kVerticalMargin;
        self.valueLabel.frame = CGRectMake(fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetWidth(self.bounds) - width), 0.f),
                                           CGRectGetMinY(thumbRect) - height - kBubbleDistance,
                                           fminf(width, CGRectGetWidth(self.bounds)),
                                           height);
        
        self.tipLayer.frame = CGRectMake(CGRectGetMidX(thumbRect) - CGRectGetWidth(self.tipLayer.frame) / 2.f,
                                         CGRectGetMaxY(self.valueLabel.frame),
                                         CGRectGetWidth(self.tipLayer.frame),
                                         CGRectGetHeight(self.tipLayer.frame));
    }
    else {
        self.valueLabel.hidden = YES;
        self.tipLayer.hidden = YES;
    }
    
    UIColor *backgroundColor = self.live ? UIColor.srg_lightRedColor : UIColor.whiteColor;
    UIColor *textColor = self.live ? UIColor.whiteColor  : UIColor.blackColor;
    
    self.tipLayer.fillColor = backgroundColor.CGColor;
    self.valueLabel.backgroundColor = backgroundColor;
    self.valueLabel.textColor = textColor;
}

@end

static void commonInit(SRGLetterboxTimeSlider *self)
{
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    valueLabel.layer.masksToBounds = YES;
    valueLabel.layer.cornerRadius = 3.f;
    valueLabel.isAccessibilityElement = NO;
    [self addSubview:valueLabel];
    self.valueLabel = valueLabel;
    
    CGFloat kTipWidth = 6.f;
    CGFloat kTipHeight = 4.f;
    
    UIBezierPath *tipPath = [UIBezierPath bezierPath];
    [tipPath moveToPoint:CGPointZero];
    [tipPath addLineToPoint:CGPointMake(kTipWidth, 0.f)];
    [tipPath addLineToPoint:CGPointMake(kTipWidth / 2.f, kTipHeight)];
    [tipPath closePath];
    
    CAShapeLayer *tipLayer = [CAShapeLayer layer];
    tipLayer.frame = CGRectMake(0.f, 0.f, kTipWidth, kTipHeight);
    tipLayer.path = tipPath.CGPath;
    tipLayer.actions = @{ @keypath(tipLayer.position) : [NSNull null],
                          @keypath(tipLayer.fillColor) : [NSNull null] };        // Disable implicit animations so that tip updates are applied instantaneously
    [self.layer addSublayer:tipLayer];
    self.tipLayer = tipLayer;
    
    [self updateLayoutForValue:self.value];
}

#endif
