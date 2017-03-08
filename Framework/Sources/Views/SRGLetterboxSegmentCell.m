//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSegmentCell.h"

#import "UIImageView+SRGLetterbox.h"

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
    self.hiddenFavoriteImage = YES;
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(longPress:)];
    longPressGestureRecognizer.minimumPressDuration = 1.f;
    [self addGestureRecognizer:longPressGestureRecognizer];
    self.longPressGestureRecognizer = longPressGestureRecognizer;
    
}



#pragma mark Getters and setters

- (void)setSegment:(SRGSegment *)segment
{
    _segment = segment;
    
    self.titleLabel.text = segment.title;
    [self.imageView srg_requestImageForObject:segment withScale:SRGImageScaleMedium placeholderImageName:@"placeholder_media-180"];
    
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    
    if (segment.duration != 0) {
        self.durationLabel.hidden = NO;
        self.durationLabel.text = [s_dateComponentsFormatter stringFromTimeInterval:segment.duration / 1000.];
    }
    else {
        self.durationLabel.hidden = YES;
    }
    
    self.alpha = (segment.blockingReason != SRGBlockingReasonNone) ? 0.5f : 1.f;
    
    BOOL hiddenFavoriteImage = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(letterboxSegmentCellHideFavoriteImage:)]) {
        hiddenFavoriteImage = [self.delegate letterboxSegmentCellHideFavoriteImage:self];
    }
    self.hiddenFavoriteImage = hiddenFavoriteImage;
}

- (void)setProgress:(float)progress
{
    self.progressView.progress = progress;
}

- (void)setCurrent:(BOOL)current
{
    self.backgroundColor = current ? [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f] : [UIColor blackColor];
}

 -(void)setHiddenFavoriteImage:(BOOL)hiddenFavoriteImage
{
    if (_hiddenFavoriteImage != hiddenFavoriteImage) {
        _hiddenFavoriteImage = hiddenFavoriteImage;
        self.favoriteImageView.alpha = hiddenFavoriteImage ? 0.f : 1.f;
    }
}

#pragma mark Gesture recognizers

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan &&
        self.delegate && [self.delegate respondsToSelector:@selector(letterboxSegmentCellDidLongPress:)]) {
        [self.delegate letterboxSegmentCellDidLongPress:self];
        
        BOOL hiddenFavoriteImage = self.hiddenFavoriteImage;
        if (self.delegate && [self.delegate respondsToSelector:@selector(letterboxSegmentCellHideFavoriteImage:)]) {
            hiddenFavoriteImage = [self.delegate letterboxSegmentCellHideFavoriteImage:self];
        }
        self.hiddenFavoriteImage = hiddenFavoriteImage;
    }
}

@end
