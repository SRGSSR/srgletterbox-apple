//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGStackView.h"

@interface UIView (SRGStackView)

@property (nonatomic, nullable) SRGStackAttributes *srg_stackAttributes;

- (CGSize)srg_systemLayoutSizeFittingSize:(CGSize)targetSize
            withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
                  verticalFittingPriority:(UILayoutPriority)verticalFittingPriority;

@end
