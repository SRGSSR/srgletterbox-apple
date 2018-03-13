//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPaddedLabel.h"

@implementation SRGPaddedLabel

#pragma mark Overrides

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = super.intrinsicContentSize;
    return CGSizeEqualToSize(intrinsicContentSize, CGSizeZero) ? intrinsicContentSize : CGSizeMake(intrinsicContentSize.width + 2 * self.horizontalMargin, intrinsicContentSize.height + 2 * self.verticalMargin);
}

#pragma mark Getters ans Setters

- (void)setHorizontalMargin:(CGFloat)horizontalMargin
{
    _horizontalMargin = horizontalMargin;
    [self layoutIfNeeded];
}

- (void)setVerticalMargin:(CGFloat)verticalMargin
{
    _verticalMargin = verticalMargin;
    [self layoutIfNeeded];
}

@end
