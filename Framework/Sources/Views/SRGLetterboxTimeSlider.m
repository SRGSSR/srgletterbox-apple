//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimeSlider.h"

#import <SRGAppearance/SRGAppearance.h>

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
    
    CGRect trackFrame = [super trackRectForBounds:self.bounds];
    CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:value];
    
    static const CGFloat kPadding = 3.f;
    static const CGFloat kBubbleDistance = 6.f;
    
    CGSize intrinsicContentSize = self.valueLabel.intrinsicContentSize;
    CGFloat width = intrinsicContentSize.width + 2 * kPadding;
    CGFloat height = intrinsicContentSize.height + 2 * kPadding;
    self.valueLabel.frame = CGRectMake(fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetWidth(self.bounds) - width), 0.f),
                                       CGRectGetMinY(thumbRect) - height - kBubbleDistance,
                                       fminf(width, CGRectGetWidth(self.bounds)),
                                       height);
    
    self.tipLayer.frame = CGRectMake(CGRectGetMidX(thumbRect) - CGRectGetWidth(self.tipLayer.frame) / 2.f,
                                     CGRectGetMaxY(self.valueLabel.frame),
                                     CGRectGetWidth(self.tipLayer.frame),
                                     CGRectGetHeight(self.tipLayer.frame));
}

@end

static void commonInit(SRGLetterboxTimeSlider *self)
{
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    valueLabel.backgroundColor = [UIColor whiteColor];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    valueLabel.layer.masksToBounds = YES;
    valueLabel.layer.cornerRadius = 1.f;
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
    tipLayer.fillColor = [UIColor whiteColor].CGColor;
    tipLayer.path = tipPath.CGPath;
    tipLayer.actions = @{ @"position" : [NSNull null] };        // Disable implicit position animations so that the tip follows position changes instantaneously
    [self.layer addSublayer:tipLayer];
    self.tipLayer = tipLayer;
}
