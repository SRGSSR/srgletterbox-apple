//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGRemainingTimeButton.h"

@implementation SRGRemainingTimeButton

- (void)resetWithRemainingTime:(NSTimeInterval)timeInterval
{
    CGFloat side = fmin(CGRectGetWidth(self.frame), CGRectGetWidth(self.frame));
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    UIBezierPath *trackCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:side / 2.f startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
    CAShapeLayer *trackCircleLayer = [[CAShapeLayer alloc] init];
    trackCircleLayer.path = trackCirclePath.CGPath;
    trackCircleLayer.strokeColor = [UIColor redColor].CGColor;
    trackCircleLayer.lineWidth = 2.f;
    trackCircleLayer.fillColor = [UIColor clearColor].CGColor;
    trackCircleLayer.strokeEnd = 1.f;
    [self.layer addSublayer:trackCircleLayer];
    
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
