//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGRemainingTimeButton.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "UIColor+SRGLetterbox.h"

@interface SRGRemainingTimeButton ()

@property (nonatomic) NSDate *targetDate;

@end

@implementation SRGRemainingTimeButton

- (void)setProgress:(float)progress withDuration:(NSTimeInterval)duration
{
    // Sanitize values
    progress = fmaxf(fminf(progress, 1.f), 0.f);
    duration = fmax(duration, 0.);
    
    self.targetDate = [NSDate.date dateByAddingTimeInterval:duration];
    
    CGFloat side = fmin(CGRectGetWidth(self.frame), CGRectGetWidth(self.frame));
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    UIBezierPath *trackCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:side / 2.f startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
    CAShapeLayer *trackCircleLayer = [[CAShapeLayer alloc] init];
    trackCircleLayer.path = trackCirclePath.CGPath;
    trackCircleLayer.strokeColor = UIColor.srg_progressRedColor.CGColor;
    trackCircleLayer.lineWidth = 2.f;
    trackCircleLayer.fillColor = UIColor.clearColor.CGColor;
    trackCircleLayer.strokeEnd = 1.f;
    [self.layer addSublayer:trackCircleLayer];
    
    UIBezierPath *progressCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:side / 2.f startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
    CAShapeLayer *progressCircleLayer = [[CAShapeLayer alloc] init];
    progressCircleLayer.path = progressCirclePath.CGPath;
    progressCircleLayer.strokeColor = UIColor.whiteColor.CGColor;
    progressCircleLayer.lineWidth = 2.f;
    progressCircleLayer.fillColor = UIColor.clearColor.CGColor;
    progressCircleLayer.strokeEnd = 1.f;
    [self.layer addSublayer:progressCircleLayer];
    
    CABasicAnimation *progressAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    progressAnimation.fromValue = @(progress);
    progressAnimation.toValue = @1.f;
    progressAnimation.duration = (1.f - progress) * duration;
    progressAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [progressCircleLayer addAnimation:progressAnimation forKey:@"drawRectStroke"];
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    NSTimeInterval timeIntervalToTargetDate = [self.targetDate timeIntervalSinceDate:NSDate.date];
    if (timeIntervalToTargetDate > 0) {
        return [NSString stringWithFormat:SRGLetterboxAccessibilityLocalizedString(@"Will play in %@", @"Continuous playback Play button label (time parameter)"), [NSDateComponentsFormatter.srg_accessibilityDateComponentsFormatter stringFromTimeInterval:timeIntervalToTargetDate]];
    }
    else {
        return SRGLetterboxAccessibilityLocalizedString(@"Play", @"Play button label");
    }
}

- (NSString *)accessibilityHint
{
    return SRGLetterboxAccessibilityLocalizedString(@"Plays the content immediately.", @"Hint for the continuous playback play button.");
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton | UIAccessibilityTraitUpdatesFrequently;
}

@end

#endif
