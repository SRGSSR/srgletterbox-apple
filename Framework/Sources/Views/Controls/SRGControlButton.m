//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlButton.h"

@implementation SRGControlButton

#pragma mark Overrides

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint pointInSelf = [self convertPoint:point toView:self];
    if (self.alpha != 0.f && [self pointInside:pointInSelf withEvent:event]) {
        return self;
    }
    else {
        return [super hitTest:point withEvent:event];
    }
}

@end
