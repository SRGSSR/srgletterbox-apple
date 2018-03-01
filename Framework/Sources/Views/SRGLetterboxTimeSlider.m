//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimeSlider.h"

#import <SRGAppearance/SRGAppearance.h>

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
    
    CGRect trackFrame = [super trackRectForBounds:self.bounds];
    CGRect thumbRect = [super thumbRectForBounds:self.bounds trackRect:trackFrame value:value];
    
    static const CGFloat kPadding = 3.f;
    static const CGFloat kBubbleDistance = 4.f;
    
    CGSize intrinsicContentSize = self.valueLabel.intrinsicContentSize;
    CGFloat width = intrinsicContentSize.width + 2 * kPadding;
    CGFloat height = intrinsicContentSize.height + 2 * kPadding;
    self.valueLabel.frame = CGRectMake(fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetWidth(self.bounds) - width), 0.f),
                                       CGRectGetMinY(thumbRect) - height - kBubbleDistance,
                                       fminf(width, CGRectGetWidth(self.bounds)),
                                       height);
}

@end

static void commonInit(SRGLetterboxTimeSlider *self)
{
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    valueLabel.backgroundColor = [UIColor whiteColor];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:valueLabel];
    self.valueLabel = valueLabel;
}
