//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGLetterboxSubdivisionCell.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"
#import "NSLayoutConstraint+SRGLetterboxPrivate.h"
#import "SRGPaddedLabel.h"
#import "UIColor+SRGLetterbox.h"
#import "UIFont+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

@import SRGAppearance;

@interface SRGLetterboxSubdivisionCell ()

@property (nonatomic, weak) UIView *wrapperView;

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) SRGPaddedLabel *durationLabel;
@property (nonatomic, weak) UIImageView *media360ImageView;

@property (nonatomic, weak) UIView *blockingOverlayView;
@property (nonatomic, weak) UIImageView *blockingReasonImageView;

@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@implementation SRGLetterboxSubdivisionCell

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self layoutContentView];
    }
    return self;
}

#pragma mark Layout

- (void)layoutContentView
{
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(longPress:)];
    longPressGestureRecognizer.minimumPressDuration = 1.;
    [self.contentView addGestureRecognizer:longPressGestureRecognizer];
    self.longPressGestureRecognizer = longPressGestureRecognizer;
    
    [self layoutWrapperViewInView:self.contentView];
    [self layoutDescriptionLayoutInView:self.contentView];
}

- (void)layoutWrapperViewInView:(UIView *)view
{
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:wrapperView];
    self.wrapperView = wrapperView;
    
    [NSLayoutConstraint activateConstraints:@[
        [wrapperView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [wrapperView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [wrapperView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [wrapperView.widthAnchor constraintEqualToAnchor:wrapperView.heightAnchor multiplier:16.f / 9.f]
    ]];
    
    [self layoutThumbnailLayoutView:wrapperView];
}

- (void)layoutThumbnailLayoutView:(UIView *)view
{
    [self layoutImageViewInView:view];
    [self layoutBlockingOverlayInView:view];
    [self createMedia360IconInView:view];
    [self layoutDurationLabelInView:view];
    [self layoutProgressViewInView:view];
}

- (void)layoutImageViewInView:(UIView *)view
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [view addSubview:imageView];
    self.imageView = imageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [imageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [imageView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    ]];
}

- (void)layoutBlockingOverlayInView:(UIView *)view
{
    UIView *blockingOverlayView = [[UIView alloc] init];
    blockingOverlayView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
    blockingOverlayView.hidden = YES;
    blockingOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:blockingOverlayView];
    self.blockingOverlayView = blockingOverlayView;
    
    [NSLayoutConstraint activateConstraints:@[
        [blockingOverlayView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [blockingOverlayView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [blockingOverlayView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [blockingOverlayView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
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

- (void)createMedia360IconInView:(UIView *)view
{
    UIImage *media360Image = [UIImage srg_letterboxImageNamed:@"360_media"];
    UIImageView *media360ImageView = [[UIImageView alloc] initWithImage:media360Image];
    media360ImageView.translatesAutoresizingMaskIntoConstraints = NO;
    media360ImageView.tintColor = UIColor.whiteColor;
    media360ImageView.layer.shadowOpacity = 0.3f;
    media360ImageView.layer.shadowRadius = 2.f;
    media360ImageView.layer.shadowOffset = CGSizeMake(0.f, 1.f);
    [view addSubview:media360ImageView];
    self.media360ImageView = media360ImageView;
    
    [NSLayoutConstraint activateConstraints:@[
        [media360ImageView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:5.f],
        [media360ImageView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-5.f],
    ]];
}

- (void)layoutDurationLabelInView:(UIView *)view
{
    SRGPaddedLabel *durationLabel = [[SRGPaddedLabel alloc] init];
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    durationLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.85f];
    durationLabel.textColor = UIColor.whiteColor;
    durationLabel.textAlignment = NSTextAlignmentCenter;
    durationLabel.horizontalMargin = 5.f;
    durationLabel.layer.cornerRadius = 3.f;
    durationLabel.layer.masksToBounds = YES;
    [view addSubview:durationLabel];
    self.durationLabel = durationLabel;
    
    [NSLayoutConstraint activateConstraints:@[
        [durationLabel.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-5.f],
        [durationLabel.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-5.f],
        [durationLabel.heightAnchor constraintEqualToConstant:18.f]
    ]];
}

- (void)layoutProgressViewInView:(UIView *)view
{
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.progressTintColor = UIColor.redColor;
    progressView.trackTintColor = [UIColor colorWithWhite:1.f alpha:0.6f];
    [view addSubview:progressView];
    self.progressView = progressView;
    
    [NSLayoutConstraint activateConstraints:@[
        [progressView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [progressView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [progressView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [progressView.heightAnchor constraintEqualToConstant:2.f]
    ]];
}

- (void)layoutDescriptionLayoutInView:(UIView *)view
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    [view addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [[stackView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:6.f] srgletterbox_withPriority:999],
        [[stackView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-6.f] srgletterbox_withPriority:999],
        [stackView.topAnchor constraintEqualToAnchor:self.wrapperView.bottomAnchor constant:2.f],
        [stackView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:3.f]
    ]];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 2;
    [stackView addArrangedSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIView *spacerView = [[UIView alloc] init];
    [stackView addArrangedSubview:spacerView];
}

#pragma mark Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.blockingOverlayView.hidden = YES;
    self.blockingReasonImageView.image = nil;
    
    [self.imageView srg_resetImage];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
}

#pragma mark Getters and setters

- (void)setSubdivision:(SRGSubdivision *)subdivision
{
    _subdivision = subdivision;
    
    self.titleLabel.text = subdivision.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    [self.imageView srg_requestImageForObject:subdivision withScale:SRGImageScaleMedium type:SRGImageTypeDefault];
    
    self.durationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    self.durationLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    
    NSString * (^formattedDuration)(NSTimeInterval) = ^(NSTimeInterval durationInSeconds) {
        if (durationInSeconds <= 60. * 60.) {
            return [NSDateComponentsFormatter.srg_shortDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
        }
        else {
            return [NSDateComponentsFormatter.srg_mediumDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
        }
    };
    
    NSDate *currentDate = NSDate.date;
    
    SRGTimeAvailability timeAvailability = [subdivision timeAvailabilityAtDate:currentDate];
    if (timeAvailability == SRGTimeAvailabilityNotYetAvailable) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Soon", @"Short label identifying content which will be available soon.").uppercaseString;
        self.durationLabel.hidden = NO;
    }
    else if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Expired", @"Short label identifying content which has expired.").uppercaseString;
        self.durationLabel.hidden = NO;
    }
    else if ([subdivision isKindOfClass:SRGSegment.class]) {
        SRGSegment *segment = (SRGSegment *)subdivision;
        if (segment.markInDate && segment.markOutDate) {
            if ([segment.markInDate compare:currentDate] != NSOrderedDescending && [currentDate compare:segment.markOutDate] != NSOrderedDescending) {
                self.durationLabel.text = SRGLetterboxLocalizedString(@"Live", @"Short label identifying a livestream. Display in uppercase.").uppercaseString;
                self.durationLabel.backgroundColor = UIColor.srg_liveRedColor;
            }
            else {
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@" ") attributes:@{ NSFontAttributeName : [UIFont srg_awesomeFontWithTextStyle:SRGAppearanceFontTextStyleCaption] }];
                [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSDateFormatter.srgletterbox_timeFormatter stringFromDate:segment.markInDate] attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption] }]];
                self.durationLabel.attributedText = attributedString.copy;
            }
            self.durationLabel.hidden = NO;
        }
        else if (segment.duration != 0) {
            self.durationLabel.text = formattedDuration(segment.duration / 1000.);
            self.durationLabel.hidden = NO;
        }
        else {
            self.durationLabel.text = nil;
            self.durationLabel.hidden = YES;
        }
    }
    else if (subdivision.contentType == SRGContentTypeLivestream || subdivision.contentType == SRGContentTypeScheduledLivestream) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Live", @"Short label identifying a livestream. Display in uppercase.").uppercaseString;
        self.durationLabel.hidden = NO;
        self.durationLabel.backgroundColor = UIColor.srg_liveRedColor;
    }
    else if (subdivision.duration != 0.) {
        self.durationLabel.text = formattedDuration(subdivision.duration / 1000.);
        self.durationLabel.hidden = NO;
    }
    else {
        self.durationLabel.text = nil;
        self.durationLabel.hidden = YES;
    }
    
    SRGBlockingReason blockingReason = [subdivision blockingReasonAtDate:currentDate];
    if (blockingReason == SRGBlockingReasonNone || blockingReason == SRGBlockingReasonStartDate) {
        self.blockingOverlayView.hidden = YES;
        self.blockingReasonImageView.image = nil;
        
        self.titleLabel.textColor = UIColor.whiteColor;
    }
    else {
        self.blockingOverlayView.hidden = NO;
        self.blockingReasonImageView.image = [UIImage srg_letterboxImageForBlockingReason:blockingReason];
        
        self.titleLabel.textColor = UIColor.lightGrayColor;
    }
    
    SRGPresentation presentation = SRGPresentationDefault;
    if ([subdivision isKindOfClass:SRGChapter.class]) {
        presentation = ((SRGChapter *)subdivision).presentation;
    }
    self.media360ImageView.hidden = (presentation != SRGPresentation360);
}

- (void)setProgress:(float)progress
{
    self.progressView.progress = progress;
}

- (void)setCurrent:(BOOL)current
{
    _current = current;
    
    if (current) {
        self.contentView.layer.cornerRadius = 4.f;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.backgroundColor = [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f];
        
        self.wrapperView.layer.cornerRadius = 0.f;
        self.wrapperView.layer.masksToBounds = NO;
    }
    else {
        self.contentView.layer.cornerRadius = 0.f;
        self.contentView.layer.masksToBounds = NO;
        self.contentView.backgroundColor = UIColor.clearColor;
        
        self.wrapperView.layer.cornerRadius = 4.f;
        self.wrapperView.layer.masksToBounds = YES;
    }
}

#pragma mark Gesture recognizers

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.delegate) {
            [self.delegate letterboxSubdivisionCellDidLongPress:self];
        }
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.subdivision.title;
}

- (NSString *)accessibilityHint
{
    return SRGLetterboxAccessibilityLocalizedString(@"Plays the content.", @"Segment or chapter cell hint");
}

@end

#endif
