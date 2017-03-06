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
 *  The progress value to display.
 */
@property (nonatomic) float progress;

/**
 *  Set to YES iff the segment is the current one.
 */
@property (nonatomic, getter=isCurrent) BOOL current;

/**
 *  Set to NO to display a favorite icon
 */
@property (nonatomic, getter=isHiddenCustomStatus) BOOL hiddenCustomStatus;

@end

NS_ASSUME_NONNULL_END
