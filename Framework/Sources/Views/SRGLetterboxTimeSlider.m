//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimeSlider.h"

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
    
    static CGFloat const kWidth = 100.f;
    static CGFloat const kHeight = 30.f;
    self.valueLabel.frame = CGRectMake(fmaxf(fminf(CGRectGetMidX(thumbRect) - kWidth / 2.f, CGRectGetWidth(self.bounds) - kWidth), 0.f),
                                       CGRectGetMinY(thumbRect) - kHeight,
                                       kWidth,
                                       kHeight);
}

@end

static void commonInit(SRGLetterboxTimeSlider *self)
{
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.backgroundColor = [UIColor whiteColor];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:valueLabel];
    self.valueLabel = valueLabel;
}
