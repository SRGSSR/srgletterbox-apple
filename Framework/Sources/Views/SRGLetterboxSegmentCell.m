//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSegmentCell.h"

#import "UIImageView+SRGLetterbox.h"
#import "NSBundle+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGLetterboxSegmentCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIImageView *favoriteImageView;

@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@implementation SRGLetterboxSegmentCell

#pragma mark View life cycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(longPress:)];
    longPressGestureRecognizer.minimumPressDuration = 1.;
    [self addGestureRecognizer:longPressGestureRecognizer];
    self.longPressGestureRecognizer = longPressGestureRecognizer;
    
    // Workaround UIImage view tint color bug
    // See http://stackoverflow.com/a/26042893/760435
    UIImage *favoriteImage = self.favoriteImageView.image;
    self.favoriteImageView.image = nil;
    self.favoriteImageView.image = favoriteImage;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.imageView srg_resetWithScale:SRGImageScaleMedium];
}

#pragma mark Getters and setters

- (void)setSegment:(SRGSegment *)segment
{
    _segment = segment;
    
    self.titleLabel.text = segment.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    [self.imageView srg_requestImageForObject:segment withScale:SRGImageScaleMedium];
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    
    self.durationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    self.durationLabel.hidden = (segment.duration == 0.f);
    
    if (! self.durationLabel.hidden) {
        NSString *durationString = [s_dateComponentsFormatter stringFromTimeInterval:segment.duration / 1000.];
        self.durationLabel.text = [NSString stringWithFormat:@"  %@  ", durationString];
    }
    else {
        self.durationLabel.text = nil;
    }
    
    self.alpha = (segment.blockingReason != SRGBlockingReasonNone) ? 0.5f : 1.f;
    self.favoriteImageView.hidden = ! self.delegate || ! [self.delegate letterboxSegmentCellShouldDisplayFavoriteIcon:self];
}

- (void)setProgress:(float)progress
{
    self.progressView.progress = progress;
}

- (void)setCurrent:(BOOL)current
{
    self.backgroundColor = current ? [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f] : [UIColor blackColor];
}

#pragma mark Gesture recognizers

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.delegate) {
            [self.delegate letterboxSegmentCellDidLongPress:self];
            self.favoriteImageView.hidden = ! [self.delegate letterboxSegmentCellShouldDisplayFavoriteIcon:self];
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

    return self.segment.title;
}

- (NSString *)accessibilityHint
{
    return SRGLetterboxAccessibilityLocalizedString(@"Plays the content.", @"Short media or segment cell hint");
}

@end
