//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGLetterboxSegmentCell;

/**
 *  Segment cell delegate protocol.
 */
@protocol SRGLetterboxSegmentCellDelegate <NSObject>

/**
 *  This method is called when the user interface made a long press on segment cell.
 */
- (void)letterboxSegmentCellDidLongPress:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

/**
 *  This method is called when the user interface needs to determine whether a favorite icon must be displayed. If no
 *  delegate has been set, no favorite icon will be displayed.
 */
- (BOOL)letterboxSegmentCellShouldDisplayFavoriteIcon:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

@end

/**
 *  Cell for displaying a segment. Values are set by the caller
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
 *  Set to `YES` iff the segment is the current one.
 */
@property (nonatomic, getter=isCurrent) BOOL current;

/**
 *  Cell optional delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGLetterboxSegmentCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
