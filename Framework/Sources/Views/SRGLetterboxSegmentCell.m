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

- (void)updateAppearanceWithTime:(NSTimeInterval)timeInSeconds currentSegment:(SRGSegment *)currentSegment
{
    // Clamp progress so that past segments have progress = 1 and future ones have progress = 0
    float progress = (timeInSeconds - self.segment.markIn / 1000.) / (self.segment.duration / 1000.);
    progress = fminf(1.f, fmaxf(0.f, progress));
    
    UIColor *selectionColor = [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f];
    
    // Current chapter / segment: Highlight and display progress
    if (self.segment == currentSegment) {
        self.backgroundColor = selectionColor;
        self.progressView.progress = progress;
    }
    // Different chapters or segments. Compare chapter URNs.
    else {
        SRGMediaURN *currentChapterURN = [currentSegment isKindOfClass:[SRGChapter class]] ? currentSegment.URN : currentSegment.fullLengthURN;
        SRGMediaURN *chapterURN = [self.segment isKindOfClass:[SRGChapter class]] ? self.segment.URN : self.segment.fullLengthURN;
        
        // Same parent media. Display progress
        if ([chapterURN isEqual:currentChapterURN]) {
            self.backgroundColor = [UIColor blackColor];
            self.progressView.progress = progress;
        }
        // Different media. Display nothing
        else {
            self.backgroundColor = [UIColor blackColor];
            self.progressView.progress = 0.f;
        }
    }
}

@end
