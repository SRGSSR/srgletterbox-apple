//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlsStackView.h"

@interface SRGControlsStackView ()

@property (nonatomic, weak) IBOutlet UISlider *timeSlider;

@end

@implementation SRGControlsStackView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Let touch events also be detected for the pop up view (which lies outside the receiver bounds)
    return [super pointInside:point withEvent:event] || [self.timeSlider pointInside:point withEvent:event];
}

@end
