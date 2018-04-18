//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIView+SRGStackView.h"

#import <objc/runtime.h>

static void *s_stackAttributesKey = &s_stackAttributesKey;

@implementation UIView (SRGStackView)

- (SRGStackAttributes *)srg_stackAttributes
{
    return objc_getAssociatedObject(self, s_stackAttributesKey);
}

- (void)setSrg_stackAttributes:(SRGStackAttributes *)stackAttributes
{
    objc_setAssociatedObject(self, s_stackAttributesKey, stackAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGSize)srg_systemLayoutSizeFittingSize:(CGSize)targetSize
            withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
                  verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    // Set the frame to zero so that the constraint-based calculation below always calculate the correct
    // value (not the case if the view is larger than the value which would be optimal for it)
    CGRect frame = self.frame;
    self.frame = CGRectZero;
    
    CGSize size = [self systemLayoutSizeFittingSize:targetSize
                      withHorizontalFittingPriority:horizontalFittingPriority
                            verticalFittingPriority:verticalFittingPriority];
    self.frame = frame;
    
    return size;
}

@end
