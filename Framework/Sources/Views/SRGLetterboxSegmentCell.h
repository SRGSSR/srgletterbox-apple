//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Cell for displaying a segment.
 */
@interface SRGLetterboxSegmentCell : UICollectionViewCell

/**
 *  The segment to display.
 */
@property (nonatomic, nullable) SRGSegment *segment;

/**
 *  Update the segment appearance for a given playback time (in seconds) and the segment currently being played (might
 *  be a chapter).
 */
- (void)updateAppearanceWithTime:(NSTimeInterval)timeInSeconds currentSegment:(SRGSegment *)currentSegment;

@end

NS_ASSUME_NONNULL_END
