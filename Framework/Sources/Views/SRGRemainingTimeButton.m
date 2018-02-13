//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGRemainingTimeButton.h"

@implementation SRGRemainingTimeButton

- (void)setProgress:(float)progress withDuration:(NSTimeInterval)duration
{
    // Sanitize values
    progress = fmaxf(fminf(progress, 1.f), 0.f);
    duration = fmax(duration, 0.);
    
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
    progressAnimation.fromValue = @(progress);
    progressAnimation.toValue = @1.f;
    progressAnimation.duration = (1.f - progress) * duration;
    progressAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [progressCircleLayer addAnimation:progressAnimation forKey:@"drawRectStroke"];
}

@end
