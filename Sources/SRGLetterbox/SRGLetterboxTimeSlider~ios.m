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
#import "UIImage+SRGLetterbox.h"

@import libextobjc;
@import SRGAppearance;

static void commonInit(SRGLetterboxTimeSlider *self);

@interface SRGLetterboxTimeSlider ()

@property (nonatomic, weak) SRGTimeSlider *slider;
@property (nonatomic, weak) UIImageView *thumbnailImageView;
@property (nonatomic, weak) UIView *blockingOverlayView;
@property (nonatomic, weak) UIImageView *blockingReasonImageView;

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateLayoutForValue:self.slider.value interactive:NO];
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    self.slider.mediaPlayerController = mediaPlayerController;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(mediaPlayerDidSeek:)
                                               name:SRGMediaPlayerSeekNotification
                                             object:mediaPlayerController];
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:SRGMediaPlayerSeekNotification
                                                object:mediaPlayerController];
}

- (void)didDetachFromController
{
    [super didDetachFromController];
    
    self.slider.mediaPlayerController = nil;
}

#pragma mark Layout

- (void)updateLayoutForValue:(float)value interactive:(BOOL)interactive
{
    CGRect trackFrame = [self.slider trackRectForBounds:self.bounds];
    CGRect thumbRect = [self.slider thumbRectForBounds:self.bounds trackRect:trackFrame value:value];
    
    static const CGFloat kHorizontalValueLabelMargin = 5.f;
    static const CGFloat kVerticalValueLabelMargin = 3.f;
    static const CGFloat kValueLabelBottomDistance = 6.f;
    static const CGFloat kHorizontalMargin = 4.f;
    
    if (self.slider.valueLabel.text.length != 0) {
        self.slider.valueLabel.hidden = NO;
        
        CGSize intrinsicContentSize = self.slider.valueLabel.intrinsicContentSize;
        CGFloat valueLabelHeight = intrinsicContentSize.height + 2 * kVerticalValueLabelMargin;
        CGRect parentFrame = [self.parentLetterboxView convertRect:self.parentLetterboxView.bounds toView:self];
        CGFloat thumbnailAspectRatio = (self.controller && self.controller.thumbnailsAspectRatio != SRGAspectRatioUndefined) ? self.controller.thumbnailsAspectRatio : 16.f / 9.f;
        
        UIEdgeInsets safeAreaInsets = self.parentLetterboxView.safeAreaInsets;
        CGRect parentSafeFrame = CGRectMake(CGRectGetMinX(parentFrame) + safeAreaInsets.left,
                                            CGRectGetMinY(parentFrame) + safeAreaInsets.top,
                                            fmaxf(CGRectGetWidth(parentFrame) - safeAreaInsets.left - safeAreaInsets.right, 0.f),
                                            fmaxf(CGRectGetHeight(parentFrame) - safeAreaInsets.top - safeAreaInsets.bottom, 0.f));
        
        CGFloat contentWidth = 0.f;
        
        BOOL thumbnailsDisplayed = interactive && self.controller.thumbnailsAvailable;
        if (thumbnailsDisplayed) {
            // TODO: Probably a better way to take the actual aspect ratio value into account to optimize the width
            //       based on width / height min / max constraints.
            contentWidth = (thumbnailAspectRatio > 1.f) ? 150.f : 70.f;
            
            self.slider.valueLabel.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            self.thumbnailImageView.alpha = 1.f;
            self.blockingOverlayView.hidden = self.blockingReasonImageView.image != nil ? NO : YES;
        }
        else {
            contentWidth = intrinsicContentSize.width + 2 * kHorizontalValueLabelMargin;
            
            self.slider.valueLabel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            self.thumbnailImageView.alpha = 0.f;
            self.blockingOverlayView.hidden = YES;
        }
        
        CGFloat width = fminf(contentWidth, CGRectGetWidth(parentSafeFrame) - 2 * kHorizontalMargin);
        CGFloat valueLabelX = fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetMaxX(parentSafeFrame) - width - kHorizontalMargin), CGRectGetMinX(parentSafeFrame) + kHorizontalMargin);
        CGFloat valueLabelY = CGRectGetMinY(thumbRect) - valueLabelHeight - kValueLabelBottomDistance;
        CGFloat thumbnailHeight = width / thumbnailAspectRatio;
        
        self.thumbnailImageView.frame = CGRectMake(valueLabelX, valueLabelY - thumbnailHeight, width, thumbnailHeight);
        self.slider.valueLabel.frame = CGRectMake(valueLabelX, valueLabelY, width, valueLabelHeight);
    }
    else {
        self.slider.valueLabel.hidden = YES;
    }
    
    self.slider.valueLabel.backgroundColor = self.live ? UIColor.srg_lightRedColor : UIColor.srg_gray23Color;
}

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToTime:(CMTime)time date:(NSDate *)date withValue:(float)value interactive:(BOOL)interactive
{
    if (interactive) {
        self.thumbnailImageView.image = [self.controller thumbnailAtTime:time];
        
        SRGBlockingReason blockingReason = [self.controller blockingReasonAtTime:time];
        self.blockingReasonImageView.image = [UIImage srg_letterboxImageForBlockingReason:blockingReason];
    }
    [self updateLayoutForValue:value interactive:interactive];
    [self.delegate timeSlider:self isMovingToTime:time date:date withValue:value interactive:interactive];
}

- (void)timeSlider:(SRGTimeSlider *)slider didStartDraggingAtTime:(CMTime)time date:(NSDate *)date withValue:(float)value
{
    [self.delegate timeSlider:self didStartDraggingAtTime:time date:date withValue:value];
}

- (void)timeSlider:(SRGTimeSlider *)slider didStopDraggingAtTime:(CMTime)time date:(NSDate *)date withValue:(float)value
{
    [self.delegate timeSlider:self didStopDraggingAtTime:time date:date withValue:value];
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

#pragma mark Notifications

- (void)mediaPlayerDidSeek:(NSNotification *)notification
{
    [self updateLayoutForValue:self.slider.value interactive:NO];
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
    thumbnailImageView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    thumbnailImageView.isAccessibilityElement = NO;
    [self.contentView addSubview:thumbnailImageView];
    self.thumbnailImageView = thumbnailImageView;
    
    UIView *blockingOverlayView = [[UIView alloc] init];
    blockingOverlayView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
    blockingOverlayView.hidden = YES;
    blockingOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:blockingOverlayView];
    self.blockingOverlayView = blockingOverlayView;
    
    [NSLayoutConstraint activateConstraints:@[
        [blockingOverlayView.leadingAnchor constraintEqualToAnchor:thumbnailImageView.leadingAnchor],
        [blockingOverlayView.trailingAnchor constraintEqualToAnchor:thumbnailImageView.trailingAnchor],
        [blockingOverlayView.topAnchor constraintEqualToAnchor:thumbnailImageView.topAnchor],
        [blockingOverlayView.bottomAnchor constraintEqualToAnchor:thumbnailImageView.bottomAnchor],
    ]];
    
    UIImageView *blockingReasonImageView = [[UIImageView alloc] init];
    blockingReasonImageView.translatesAutoresizingMaskIntoConstraints = NO;
    blockingReasonImageView.tintColor = UIColor.whiteColor;
    [blockingOverlayView addSubview:blockingReasonImageView];
    self.blockingReasonImageView = blockingReasonImageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [blockingReasonImageView.centerXAnchor constraintEqualToAnchor:blockingOverlayView.centerXAnchor],
        [blockingReasonImageView.centerYAnchor constraintEqualToAnchor:blockingOverlayView.centerYAnchor]
    ]];
}

#endif
