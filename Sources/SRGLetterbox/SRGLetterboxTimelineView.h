//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"
#import "SRGLetterboxSubdivisionCell.h"

@import CoreMedia;
@import SRGDataProvider;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

// The standard timeline height.
static const CGFloat SRGLetterboxTimelineViewDefaultHeight = 120.f;

// Forward declarations.
@class SRGLetterboxTimelineView;

/**
 *  Timeline delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGLetterboxTimelineViewDelegate <NSObject>

/**
 *  Called when a subdivision (segment or chapter) has been actively selected by the user.
 */
- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didSelectSubdivision:(SRGSubdivision *)subdivision;

/**
 *  Called when the user made a long press on subdivision cell.
 */
- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didLongPressSubdivision:(SRGSubdivision *)subdivision;

@end

/**
 *  Timeline displaying subdivisions (segments and chapters) associated with a media.
 */
API_UNAVAILABLE(tvos)
@interface SRGLetterboxTimelineView : SRGLetterboxControllerView <UICollectionViewDataSource, UICollectionViewDelegate, SRGLetterboxSubdivisionCellDelegate>

/**
 *  The timeline delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxTimelineViewDelegate> delegate;

/**
 *  The subdivisions (segments or chapters) displayed by the timeline.
 */
@property (nonatomic, readonly, nullable) NSArray<SRGSubdivision *> *subdivisions;

/**
 *  The time to display the timeline progress for.
 */
@property (nonatomic) CMTime time;

/**
 *  The index of the cell to be selected, if any. Set to `NSNotFound` for none.
 */
@property (nonatomic) NSUInteger selectedIndex;

/**
 *  Scroll the timeline to the current selection. Does nothing if the user is actively dragging the timeline.
 */
- (void)scrollToCurrentSelectionAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
