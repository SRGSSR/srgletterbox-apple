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
    static const CGFloat kHorizontalMargin = 2.f;
    static const CGFloat kVerticalMargin = 2.f;
    
    CGSize intrinsicContentSize = super.intrinsicContentSize;
    return CGSizeEqualToSize(intrinsicContentSize, CGSizeZero) ? intrinsicContentSize : CGSizeMake(intrinsicContentSize.width + 2 * kHorizontalMargin, intrinsicContentSize.height + 2 * kVerticalMargin);
}

@end

static void commonInit(SRGPaddedLabel *self)
{
    self.backgroundColor = [UIColor colorWithWhite:0.f alpha:.75f];
    self.textColor = [UIColor whiteColor];
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4.f;
    
    self.hidden = NO;
}
