//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLabeledControlButton.h"

@implementation SRGLabeledControlButton

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        // Trick to avoid incorrect truncation when Bold text has been enabled in system settings
        // See https://developer.apple.com/forums/thread/125492
        self.titleLabel.lineBreakMode = NSLineBreakByClipping;
        
        [self setTitleColor:[UIColor colorWithWhite:0.5f alpha:1.f] forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor colorWithWhite:0.8f alpha:0.75f] forState:UIControlStateDisabled];
    }
    return self;
}

#pragma mark Getters and setters

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    [self setTitleColor:tintColor forState:UIControlStateNormal];    
}

- (void)setVerticalOffset:(CGFloat)verticalOffset
{
    _verticalOffset = verticalOffset;
    
    [self setNeedsLayout];
}

#pragma mark Overrides

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
                                       CGRectGetHeight(self.bounds) - self.verticalOffset,
                                       CGRectGetWidth(titleFrame),
                                       CGRectGetHeight(titleFrame));
}

@end
