//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPaddedLabel.h"

static void commonInit(SRGPaddedLabel *self);

@implementation SRGPaddedLabel

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

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

static void commonInit(SRGPaddedLabel *self)
{
    self.layer.masksToBounds = YES;
    self.hidden = NO;
}
