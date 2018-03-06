//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlWrapperView.h"

@implementation SRGControlWrapperView

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return (self.wrappedView) ? @[self.wrappedView] : nil;
}

@end
