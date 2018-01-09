//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

#import "SRGLetterboxSubdivisionCell.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@class SRGLetterboxTimelineView;

/**
 *  Timeline delegate protocol.
 */
@protocol SRGLetterboxTimelineViewDelegate <NSObject>

/**
 *  Called when a subdivision (segment or chapter) has been actively selected by the user.
 */
- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didSelectSubdivision:(SRGSubdivision *)subdivision;

/**
 *  Called when the user made a long press on subdivision cell.
 */
- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didLongPressSubdivision:(SRGSubdivision *)subdivision;

/**
 *  Called when the user interface needs to determine whether a favorite icon must be displayed. If no delegate has been
 *  set, no favorite icon will be displayed.
 */
- (BOOL)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView shouldDisplayFavoriteForSubdivision:(SRGSubdivision *)subdivision;

@end

/**
 *  Timeline displaying subdivisions (segments and chapters) associated with a media.
 */
IB_DESIGNABLE
@interface SRGLetterboxTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate, SRGLetterboxSubdivisionCellDelegate>

/**
 *  The timeline delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxTimelineViewDelegate> delegate;

/**
 *  The full length URN currently played.
 */
@property (nonatomic, nullable) SRGMediaURN *fullLengthURN;

/**
 *  The subdivisions (segments or chapters) displayed by the timeline.
 */
@property (nonatomic, nullable) NSArray<SRGSubdivision *> *subdivisions;

/**
 *  The time to display the timeline progress for.
 */
@property (nonatomic) CMTime time;

/**
 *  The index of the cell to be selected, if any. Set to `NSNotFound` for none.
 */
@property (nonatomic) NSUInteger selectedIndex;

/**
 *  Scroll the timeline to the selected index, if any. Does nothing if the user is actively dragging the timeline.
 */
- (void)scrollToSelectedIndexAnimated:(BOOL)animated;

/**
 *  Call to ask for a subdivision favorite status update.
 */
- (void)setNeedsSubdivisionFavoritesUpdate;

@end

NS_ASSUME_NONNULL_END
