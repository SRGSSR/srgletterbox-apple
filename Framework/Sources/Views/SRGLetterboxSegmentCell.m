//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSegmentCell.h"

#import "UIImageView+SRGLetterbox.h"

@interface SRGLetterboxSegmentCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation SRGLetterboxSegmentCell

#pragma mark Getters and setters

- (void)setSegment:(SRGSegment *)segment
{
    _segment = segment;
    
    [self.imageView srg_requestImageForObject:segment withScale:SRGImageScaleMedium placeholderImageName:@"placeholder_media-180"];
}

@end
