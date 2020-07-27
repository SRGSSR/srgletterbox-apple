//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLiveLabel.h"

#import "NSBundle+SRGLetterbox.h"
#import "UIColor+SRGLetterbox.h"

@import SRGAppearance;

static void commonInit(SRGLiveLabel *self);

@interface SRGLiveLabel ()

@property (nonatomic, weak) UILabel *label;

@end

@implementation SRGLiveLabel

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
    static const CGFloat kHorizontalMargin = 5.f;
    static const CGFloat kHeight = 19.f;
    
    CGSize intrinsicContentSize = self.label.intrinsicContentSize;
    return CGSizeEqualToSize(intrinsicContentSize, CGSizeZero) ? intrinsicContentSize : CGSizeMake(intrinsicContentSize.width + 2 * kHorizontalMargin, kHeight);
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return SRGLetterboxAccessibilityLocalizedString(@"Live playback", @"Live label when playing live.");
}

@end

static void commonInit(SRGLiveLabel *self)
{
    // Unlike `UIView`, setting a corner radius AND a shadow on a `UILabel` does not work.
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.textColor = UIColor.whiteColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:label];
    self.label = label;
    
    label.text = SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live only stream or a DVR stream in live").uppercaseString;
#if TARGET_OS_TV
    label.font = [UIFont srg_boldFontWithSize:26.f];
#else
    label.font = [UIFont srg_boldFontWithSize:14.f];
#endif
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    
    self.backgroundColor = UIColor.srg_liveRedColor;
    self.layer.cornerRadius = 3.f;
}
