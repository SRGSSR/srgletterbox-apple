//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLiveLabel.h"

#import "NSBundle+SRGLetterbox.h"
#import "UIColor+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

static void commonInit(SRGLiveLabel *self);

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
    
    CGSize intrinsicContentSize = super.intrinsicContentSize;
    return CGSizeEqualToSize(intrinsicContentSize, CGSizeZero) ? intrinsicContentSize : CGSizeMake(intrinsicContentSize.width + 2 * kHorizontalMargin, kHeight);
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return SRGLetterboxAccessibilityLocalizedString(@"Live playback", @"Live label when playing live.");
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    commonInit(self);
}

@end

static void commonInit(SRGLiveLabel *self)
{
    self.layer.masksToBounds = YES;
    self.backgroundColor = UIColor.srg_liveRedColor;
    self.textColor = UIColor.whiteColor;
    self.text = SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live only stream or a DVR stream in live").uppercaseString;
#if TARGET_OS_TV
    self.font = [UIFont srg_boldFontWithSize:26.f];
    self.layer.cornerRadius = 2.f;
#else
    self.font = [UIFont srg_boldFontWithSize:14.f];
    self.layer.cornerRadius = 1.f;
#endif
    self.textAlignment = NSTextAlignmentCenter;
    self.numberOfLines = 1;
}
