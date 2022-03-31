//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxTimeSlider.h"
#import "UIColor+SRGLetterbox.h"
#import "UIFont+SRGLetterbox.h"

@import libextobjc;
@import SRGAppearance;

static void commonInit(SRGLetterboxTimeSlider *self);

@interface SRGLetterboxTimeSlider ()

@property (nonatomic, weak) SRGTimeSlider *slider;
@property (nonatomic, weak) UIImageView *thumbnailImageView;

@end

@implementation SRGLetterboxTimeSlider

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

#pragma mark Getters

- (CMTime)time
{
    return self.slider.time;
}

- (NSDate *)date
{
    return self.slider.date;
}

- (BOOL)isLive
{
    return self.slider.live;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return (self.alpha != 0);
}

#pragma mark Overrides

- (void)didAttachToController
{
    [super didAttachToController];
    
    self.slider.mediaPlayerController = self.controller.mediaPlayerController;
}

- (void)didDetachFromController
{
    [super didDetachFromController];
    
    self.slider.mediaPlayerController = nil;
}

#pragma mark Layout

- (void)updateLayoutForValue:(float)value
{
    CGRect trackFrame = [self.slider trackRectForBounds:self.bounds];
    CGRect thumbRect = [self.slider thumbRectForBounds:self.bounds trackRect:trackFrame value:value];
    
    static const CGFloat kHorizontalMargin = 5.f;
    static const CGFloat kVerticalMargin = 3.f;
    static const CGFloat kBubbleDistance = 6.f;
    
    if (self.slider.valueLabel.text.length != 0) {
        self.slider.valueLabel.hidden = NO;
        
        CGSize intrinsicContentSize = self.slider.valueLabel.intrinsicContentSize;
        CGFloat width = intrinsicContentSize.width + 2 * kHorizontalMargin;
        CGFloat height = intrinsicContentSize.height + 2 * kVerticalMargin;
        
        CGRect valueLabelFrame = CGRectMake(fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetWidth(self.bounds) - width), 0.f),
                                            CGRectGetMinY(thumbRect) - height - kBubbleDistance,
                                            fminf(width, CGRectGetWidth(self.bounds)),
                                            height);
        self.slider.valueLabel.frame = valueLabelFrame;
        self.thumbnailImageView.frame = CGRectMake(CGRectGetMidX(thumbRect) - 150.f / 2.f,
                                                   CGRectGetMinY(valueLabelFrame) - 84.f,
                                                   150.f,
                                                   84.f);
    }
    else {
        self.slider.valueLabel.hidden = YES;
    }
    
    self.slider.valueLabel.backgroundColor = self.live ? UIColor.srg_lightRedColor : UIColor.srg_gray23Color;
}

- (UIImage *)thumbnailAtTime:(CMTime)time
{
    SRGBlockingReason blockingReason = [self.controller blockingReasonAtTime:time];
    if (blockingReason == SRGBlockingReasonNone) {
        return [self.controller thumbnailAtTime:time];
    }
    else {
        return nil;
    }
}

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToTime:(CMTime)time date:(NSDate *)date withValue:(float)value interactive:(BOOL)interactive
{
    if (self.thumbnailImageView.alpha == 1.f) {
        self.thumbnailImageView.image = [self thumbnailAtTime:time];
    }
    [self updateLayoutForValue:value];
    [self.delegate timeSlider:self isMovingToTime:time date:date withValue:value interactive:interactive];
}

- (void)timeSlider:(SRGTimeSlider *)slider didStartDraggingAtTime:(CMTime)time
{
    [UIView animateWithDuration:0.1 animations:^{
        self.thumbnailImageView.alpha = 1.f;
    }];
    [self.delegate timeSlider:self didStartDraggingAtTime:time];
}

- (void)timeSlider:(SRGTimeSlider *)slider didStopDraggingAtTime:(CMTime)time
{
    [UIView animateWithDuration:0.1 animations:^{
        self.thumbnailImageView.alpha = 0.f;
    }];
    [self.delegate timeSlider:self didStopDraggingAtTime:time];
}

- (NSAttributedString *)timeSlider:(SRGTimeSlider *)slider labelForValue:(float)value time:(CMTime)time date:(NSDate *)date
{
    SRGMediaPlayerStreamType streamType = slider.mediaPlayerController.streamType;
    if (slider.live) {
        return [[NSAttributedString alloc] initWithString:SRGLetterboxLocalizedString(@"Live", @"Very short text in the slider bubble, or in the bottom right corner of the Letterbox view when playing a live only stream or a DVR stream in live").uppercaseString attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightBold fixedSize:14.f] }];
    }
    else if (streamType == SRGMediaPlayerStreamTypeDVR) {
        if (date) {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@" ") attributes:@{ NSFontAttributeName : [UIFont srg_awesomeFontWithSize:14.f] }];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSDateFormatter.srgletterbox_timeFormatter stringFromDate:date] attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:14.f] }]];
            return attributedString.copy;
        }
        else {
            return [[NSAttributedString alloc] initWithString:@"--:--" attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:14.f] }];
        }
    }
    else if (streamType == SRGMediaPlayerStreamTypeLive) {
        return nil;
    }
    else {
        NSDateComponentsFormatter *dateComponentsFormatter = (fabsf(value) < 60.f * 60.f) ? NSDateComponentsFormatter.srg_shortDateComponentsFormatter : NSDateComponentsFormatter.srg_mediumDateComponentsFormatter;
        NSString *string = [dateComponentsFormatter stringFromTimeInterval:value];
        return [[NSAttributedString alloc] initWithString:string attributes:@{ NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightMedium fixedSize:14.f] }];
    }
}

- (void)timeSlider:(SRGTimeSlider *)slider accessibilityDecrementFromValue:(float)value time:(CMTime)time
{
    [self.controller skipWithInterval:-SRGLetterboxBackwardSkipInterval completionHandler:nil];
}

- (void)timeSlider:(SRGTimeSlider *)slider accessibilityIncrementFromValue:(float)value time:(CMTime)time
{
    [self.controller skipWithInterval:SRGLetterboxForwardSkipInterval completionHandler:nil];
}

@end

static void commonInit(SRGLetterboxTimeSlider *self)
{
    SRGTimeSlider *slider = [[SRGTimeSlider alloc] initWithFrame:self.bounds];
    slider.delegate = self;
    slider.minimumTrackTintColor = UIColor.whiteColor;
    slider.maximumTrackTintColor = [UIColor colorWithWhite:1.f alpha:0.3f];
    slider.bufferingTrackColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    slider.resumingAfterSeek = YES;
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:slider];
    self.slider = slider;
    
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    valueLabel.textColor = UIColor.whiteColor;
    valueLabel.layer.masksToBounds = YES;
    valueLabel.layer.cornerRadius = 3.f;
    valueLabel.isAccessibilityElement = NO;
    [self.contentView addSubview:valueLabel];
    slider.valueLabel = valueLabel;
    
    UIImageView *thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
    thumbnailImageView.alpha = 0.f;
    thumbnailImageView.layer.masksToBounds = YES;
    thumbnailImageView.layer.cornerRadius = 3.f;
    thumbnailImageView.isAccessibilityElement = NO;
    [self.contentView addSubview:thumbnailImageView];
    self.thumbnailImageView = thumbnailImageView;
    
    [self updateLayoutForValue:self.slider.value];
}

#endif
