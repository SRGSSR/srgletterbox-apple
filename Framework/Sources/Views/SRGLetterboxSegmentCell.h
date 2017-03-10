//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxSegmentCell;

/**
 *  Letterbox segment cell delegate protocol for long press or favorite image
 */
@protocol SRGLetterboxSegmentCellDelegate <NSObject>

/**
 *  This method gets called when the user interface made a long press on segment cell
 *
 *  @discussion Method to be inform about the user interaction. Could save a state.
 *  Just after this call, the method `letterboxSegmentCellHideFavoriteImage:` will be called.
 */
- (void)letterboxSegmentCellDidLongPress:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

/**
 *  This method gets called when the user interface is about to display a segment cell or when a long press has been
 *  fired. By defaut, if non implemented, the behavior is the same as if the method returns `NO`.
 */
- (BOOL)letterboxSegmentCellShouldFavorite:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

@end

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
@property (nonatomic, getter=isFavoriteImageHidden) BOOL favoriteImageHidden;

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGLetterboxSegmentCellDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
