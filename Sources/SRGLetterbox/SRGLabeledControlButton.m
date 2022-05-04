//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLabeledControlButton.h"

@implementation SRGLabeledControlButton

#pragma mark Overrides

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setTitleColor:[UIColor colorWithWhite:0.5f alpha:1.f] forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor colorWithWhite:0.8f alpha:0.75f] forState:UIControlStateDisabled];
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    [self setTitleColor:tintColor forState:UIControlStateNormal];    
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect imageFrame = self.imageView.frame;
    self.imageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(imageFrame)) / 2.f,
                                      (CGRectGetHeight(self.bounds) - CGRectGetHeight(imageFrame)) / 2.f,
                                      CGRectGetWidth(imageFrame),
                                      CGRectGetHeight(imageFrame));
    
    CGRect titleFrame = self.titleLabel.frame;
    self.titleLabel.frame = CGRectMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(titleFrame)) / 2.f,
                                       CGRectGetHeight(self.bounds) - CGRectGetHeight(titleFrame) + 4.f,
                                       CGRectGetWidth(titleFrame),
                                       CGRectGetHeight(titleFrame));
}

@end
