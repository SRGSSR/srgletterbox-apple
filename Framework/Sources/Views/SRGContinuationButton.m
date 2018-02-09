//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuationButton.h"

#import <SRGAppearance/SRGAppearance.h>

@implementation SRGContinuationButton

- (void)resetWithRemainingTime:(NSTimeInterval)timeInterval
{
    CGFloat side = fmin(CGRectGetWidth(self.frame), CGRectGetWidth(self.frame));
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    UIBezierPath *backgroundCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:side / 2.f startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
    CAShapeLayer *backgroundCircleLayer = [[CAShapeLayer alloc] init];
    backgroundCircleLayer.path = backgroundCirclePath.CGPath;
    backgroundCircleLayer.strokeColor = [UIColor srg_redColor].CGColor;
    backgroundCircleLayer.lineWidth = 2.f;
    backgroundCircleLayer.fillColor = [UIColor clearColor].CGColor;
    backgroundCircleLayer.strokeEnd = 1.f;
    [self.layer addSublayer:backgroundCircleLayer];
    
    UIBezierPath *progressCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:side / 2.f startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
    CAShapeLayer *progressCircleLayer = [[CAShapeLayer alloc] init];
    progressCircleLayer.path = progressCirclePath.CGPath;
    progressCircleLayer.strokeColor = [UIColor whiteColor].CGColor;
    progressCircleLayer.lineWidth = 2.f;
    progressCircleLayer.fillColor = [UIColor clearColor].CGColor;
    progressCircleLayer.strokeEnd = 1.f;
    [self.layer addSublayer:progressCircleLayer];
    
    CABasicAnimation *progressAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    progressAnimation.fromValue = (id)[NSNumber numberWithFloat:0.1f];
    progressAnimation.toValue = (id)[NSNumber numberWithFloat:1.f];
    progressAnimation.duration = timeInterval;
    progressAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [progressCircleLayer addAnimation:progressAnimation forKey:@"drawRectStroke"];
}

@end
