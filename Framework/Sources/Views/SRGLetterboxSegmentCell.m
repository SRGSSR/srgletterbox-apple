//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSegmentCell.h"

#import "UIImageView+SRGLetterbox.h"

@interface SRGLetterboxSegmentCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation SRGLetterboxSegmentCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark Getters and setters

- (void)setSegment:(SRGSegment *)segment
{
    _segment = segment;
    
    self.titleLabel.text = segment.title;
    [self.imageView srg_requestImageForObject:segment withScale:SRGImageScaleMedium placeholderImageName:@"placeholder_media-180"];
}

@end
