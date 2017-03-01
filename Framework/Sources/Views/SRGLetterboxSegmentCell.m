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

- (void)setProgress:(float)progress
{
    self.progressView.progress = progress;
}

#pragma mark Overrides

- (void)setSelected:(BOOL)selected
{
    super.selected = selected;
    
    self.backgroundColor = selected ? [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f] : [UIColor blackColor];
}

@end
