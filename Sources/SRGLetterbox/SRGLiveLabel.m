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

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return SRGLetterboxAccessibilityLocalizedString(@"Live playback", @"Live label when playing live.");
}

@end

static void commonInit(SRGLiveLabel *self)
{
    // Unlike `UIView`, setting a corner radius AND a shadow on a `UILabel` does not work.
    UILabel *label = [[UILabel alloc] init];
    label.textColor = UIColor.whiteColor;
    [self addSubview:label];
    self.label = label;
    
#if TARGET_OS_TV
    static CGFloat kfontSize = 26.f;
    static CGFloat kMargin = 10.f;
#else
    static CGFloat kfontSize = 14.f;
    static CGFloat kMargin = 5.f;
#endif
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.topAnchor],
        [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:kMargin],
        [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-kMargin]
    ]];
    
    label.text = SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live only stream or a DVR stream in live").uppercaseString;
    label.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightBold fixedSize:kfontSize];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    
    self.backgroundColor = UIColor.srg_lightRedColor;
    self.layer.cornerRadius = 3.f;
}
