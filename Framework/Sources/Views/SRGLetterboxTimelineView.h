//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

#import "SRGLetterboxSegmentCell.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGLetterboxTimelineView;

/**
 *  Timeline delegate protocol.
 */
@protocol SRGLetterboxTimelineViewDelegate <NSObject>

/**
 *  Called when a segment has been actively selected by the user.
 */
- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView didSelectSegment:(SRGSegment *)segment;

@optional

/**
 *  This method gets called when the user makes a long press on a segment cell
 *  By defaut, if non implemented, return NO.
 */
- (BOOL)letterboxTimelineViewShouldRecognizeLongPressOnSegmentViews:(SRGLetterboxTimelineView *)timelineView;

/**
 *  This method gets called when the user interface made a long press on segment cell
 *
 *  @discussion Method to be inform about the user interaction. Could save a state.
 *  Just after this call, the method `letterboxTimelineView:shouldHideCustomStatusImageForSegment:` will be called.
 */
- (void)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView longPressRecognizedOnSegment:(SRGSegment *)segment;

/**
 *  This method gets called when the user interface is about to display a segment cell.
 *  By defaut, if non implemented, return YES.
 */
- (BOOL)letterboxTimelineView:(SRGLetterboxTimelineView *)timelineView shouldHideCustomStatusImageForSegment:(SRGSegment *)segment;

@end

/**
 *  Timeline displaying segments associated with a media.
 */
IB_DESIGNABLE
@interface SRGLetterboxTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate, SRGLetterboxSegmentCellDelegate>

/**
 *  The timeline delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxTimelineViewDelegate> delegate;

/**
 *  The segments displayed by the timeline.
 */
@property (nonatomic, nullable) NSArray<SRGSegment *> *segments;

/**
 *  The time to display the timeline for.
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

@end

NS_ASSUME_NONNULL_END
