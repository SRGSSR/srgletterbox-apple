//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import CoreMedia;
@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGLetterboxSubdivisionCell;

/**
 *  Subdivision cell delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGLetterboxSubdivisionCellDelegate <NSObject>

/**
 *  Called when the user interface made a long press on subdivision cell.
 */
- (void)letterboxSubdivisionCellDidLongPress:(SRGLetterboxSubdivisionCell *)letterboxSubdivisionCell;

@end

/**
 *  Cell for displaying a subdivision (chapter or segment). Values are set by the caller.
 */
API_UNAVAILABLE(tvos)
@interface SRGLetterboxSubdivisionCell : UICollectionViewCell

/**
 *  The subdivision (segment or chapter) to display.
 */
@property (nonatomic, nullable) SRGSubdivision *subdivision;

/**
 *  The progress value to display.
 */
@property (nonatomic) float progress;

/**
 *  Set to `YES` iff the subdivision is the current one.
 */
@property (nonatomic, getter=isCurrent) BOOL current;

/**
 *  Cell optional delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxSubdivisionCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
