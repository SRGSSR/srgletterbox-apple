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

static const CGFloat kPreviewHorizontalMargin = 4.f;
static const CGFloat kPreviewVerticalDistance = 6.f;

static void commonInit(SRGLetterboxTimeSlider *self);

@interface SRGLetterboxTimeSlider ()

@property (nonatomic, weak) SRGTimeSlider *slider;
@property (nonatomic, weak) UIImageView *thumbnailImageView;
@property (nonatomic, weak) UIImageView *blockingReasonImageView;

@property (nonatomic, weak) id periodicTimeObserver;

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
    return NO;
}

- (NSArray *)accessibilityElements
{
    return (self.alpha != 0) ? @[self.slider] : @[];
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
    
    @weakify(self)
    self.periodicTimeObserver = [mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        [self updateLayoutForValue:self.slider.value interactive:NO];
    }];
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:SRGMediaPlayerSeekNotification
                                                object:mediaPlayerController];
    
    [mediaPlayerController removePeriodicTimeObserver:self.periodicTimeObserver];
}

- (void)didDetachFromController
{
    [super didDetachFromController];
    
    self.slider.mediaPlayerController = nil;
}

#pragma mark Layout

- (void)updateLayoutForValue:(float)value interactive:(BOOL)interactive
{
    if (self.slider.valueLabel.text.length != 0) {
        self.slider.valueLabel.hidden = NO;
        
        CGRect parentFrame = [self parentFrame];
        CGSize valueLabelSize = [self valueLabelSizeInFrame:parentFrame];
        CGSize thumbnailSize = [self thumbnailSizeInFrame:parentFrame interactive:interactive];
        
        if (! CGSizeEqualToSize(thumbnailSize, CGSizeZero)) {
            CGPoint position = [self positionForFrameWithWidth:thumbnailSize.width inFrame:parentFrame atValue:value];
            
            CGFloat valueLabelY = position.y - valueLabelSize.height - kPreviewVerticalDistance;
            self.slider.valueLabel.frame = CGRectMake(position.x,
                                                      valueLabelY,
                                                      thumbnailSize.width,
                                                      valueLabelSize.height);
            self.slider.valueLabel.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            
            self.thumbnailImageView.alpha = 1.f;
            self.thumbnailImageView.frame = CGRectMake(position.x,
                                                       valueLabelY - thumbnailSize.height,
                                                       thumbnailSize.width,
                                                       thumbnailSize.height);
            
            self.blockingReasonImageView.alpha = 1.f;
        }
        else {
            CGPoint position = [self positionForFrameWithWidth:valueLabelSize.width inFrame:parentFrame atValue:value];
            
            self.slider.valueLabel.frame = CGRectMake(position.x,
                                                      position.y - valueLabelSize.height - kPreviewVerticalDistance,
                                                      valueLabelSize.width,
                                                      valueLabelSize.height);
            self.slider.valueLabel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            
            self.thumbnailImageView.alpha = 0.f;
            self.blockingReasonImageView.alpha = 0.f;
        }
    }
    else {
        self.slider.valueLabel.hidden = YES;
    }
    
    self.slider.valueLabel.backgroundColor = self.live ? UIColor.srg_lightRedColor : UIColor.srg_gray23Color;
}

- (CGRect)parentFrame
{
    CGRect parentFrame = [self.parentLetterboxView convertRect:self.parentLetterboxView.bounds toView:self];
    UIEdgeInsets safeAreaInsets = self.parentLetterboxView.safeAreaInsets;
    return CGRectMake(CGRectGetMinX(parentFrame) + safeAreaInsets.left,
                      CGRectGetMinY(parentFrame) + safeAreaInsets.top,
                      fmaxf(CGRectGetWidth(parentFrame) - safeAreaInsets.left - safeAreaInsets.right, 0.f),
                      fmaxf(CGRectGetHeight(parentFrame) - safeAreaInsets.top - safeAreaInsets.bottom, 0.f));
}

- (CGSize)valueLabelSizeInFrame:(CGRect)frame
{
    static const CGFloat kHorizontalMargin = 5.f;
    static const CGFloat kVerticalMargin = 3.f;
    
    CGSize intrinsicContentSize = self.slider.valueLabel.intrinsicContentSize;
    return CGSizeMake(fminf(intrinsicContentSize.width + 2 * kHorizontalMargin, CGRectGetWidth(frame) - 2 * kPreviewHorizontalMargin),
                      fminf(intrinsicContentSize.height + 2 * kVerticalMargin, CGRectGetHeight(frame)));
}

- (CGPoint)positionForFrameWithWidth:(CGFloat)width inFrame:(CGRect)frame atValue:(float)value
{
    CGRect trackFrame = [self.slider trackRectForBounds:self.bounds];
    CGRect thumbRect = [self.slider thumbRectForBounds:self.bounds trackRect:trackFrame value:value];
    CGFloat x = fmaxf(fminf(CGRectGetMidX(thumbRect) - width / 2.f, CGRectGetMaxX(frame) - width - kPreviewHorizontalMargin), CGRectGetMinX(frame) + kPreviewHorizontalMargin);
    CGFloat y = CGRectGetMinY(thumbRect);
    return CGPointMake(x, y);
}

- (CGSize)thumbnailSizeInFrame:(CGRect)frame interactive:(BOOL)interactive
{
    BOOL shouldDisplayThumbnails = interactive && self.controller.thumbnailsAvailable;
    if (! shouldDisplayThumbnails) {
        return CGSizeZero;
    }
    
    static const CGFloat kMinSide = 80.f;
    static const CGFloat kMaxSide = 150.f;
    
    CGFloat aspectRatio = (self.controller && self.controller.thumbnailsAspectRatio != SRGAspectRatioUndefined) ? self.controller.thumbnailsAspectRatio : 16.f / 9.f;
    CGFloat width = fminf((aspectRatio > 1.f) ? kMaxSide : kMinSide, CGRectGetWidth(frame) - 2 * kPreviewHorizontalMargin);
    CGFloat height = fmin(width / aspectRatio, kMaxSide);
    if (height + kPreviewVerticalDistance + 70.f > CGRectGetHeight(frame)) {
        return CGSizeZero;
    }
    
    return CGSizeMake(width, height);
}

#pragma mark SRGTimeSliderDelegate protocol

- (void)timeSlider:(SRGTimeSlider *)slider isMovingToTime:(CMTime)time date:(NSDate *)date withValue:(float)value interactive:(BOOL)interactive
{
    if (interactive) {
        SRGBlockingReason blockingReason = [self.controller blockingReasonAtTime:time];

        self.thumbnailImageView.image = (blockingReason == SRGBlockingReasonNone) ? [self.controller thumbnailAtTime:time] : nil;
        self.blockingReasonImageView.image = [UIImage srg_letterboxImageForBlockingReason:blockingReason];
        
        [self updateLayoutForValue:value interactive:YES];
    }
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
    [self.contentView addSubview:valueLabel];
    slider.valueLabel = valueLabel;
    
    UIImageView *thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    thumbnailImageView.backgroundColor = UIColor.blackColor;
    thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
    thumbnailImageView.alpha = 0.f;
    thumbnailImageView.layer.masksToBounds = YES;
    thumbnailImageView.layer.cornerRadius = 3.f;
    thumbnailImageView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.contentView addSubview:thumbnailImageView];
    self.thumbnailImageView = thumbnailImageView;
    
    UIImageView *blockingReasonImageView = [[UIImageView alloc] init];
    blockingReasonImageView.translatesAutoresizingMaskIntoConstraints = NO;
    blockingReasonImageView.alpha = 0.f;
    blockingReasonImageView.tintColor = UIColor.whiteColor;
    [self.contentView addSubview:blockingReasonImageView];
    self.blockingReasonImageView = blockingReasonImageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [blockingReasonImageView.centerXAnchor constraintEqualToAnchor:thumbnailImageView.centerXAnchor],
        [blockingReasonImageView.centerYAnchor constraintEqualToAnchor:thumbnailImageView.centerYAnchor]
    ]];
}

#endif
