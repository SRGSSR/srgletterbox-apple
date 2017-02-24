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

@end

@implementation SRGLetterboxSegmentCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.progressView.progress = 0.f;
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
}

#pragma mark UI

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(SRGSegment *)selectedSegment
{
    float progress = (CMTimeGetSeconds(time) - self.segment.markIn) / self.segment.duration;
    progress = fminf(1.f, fmaxf(0.f, progress));
    
    self.progressView.progress = progress;
    
    UIColor *selectionColor = [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f];
    if (selectedSegment) {
        self.backgroundColor = (self.segment == selectedSegment) ? selectionColor : [UIColor blackColor];
    }
    else {
        self.backgroundColor = (progress != 0.f && progress != 1.f) ? selectionColor : [UIColor blackColor];
    }
}

@end
