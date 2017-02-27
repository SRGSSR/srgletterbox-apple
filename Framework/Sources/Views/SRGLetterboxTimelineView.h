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
@class SRGLetterboxTimelineView;

/**
 *  Timeline delegate protocol.
 */
@protocol SRGLetterboxTimelineViewDelegate <NSObject>

/**
 *  Called when a segment has been actively selected by the user.
 */
- (void)timelineView:(SRGLetterboxTimelineView *)timelineView didSelectSegment:(SRGSegment *)segment;

/**
 *  Called when the timeline did scroll, either interactively or programmatically.
 */
- (void)timelineViewDidScroll:(SRGLetterboxTimelineView *)timelineView;

@end

/**
 *  Timeline displaying segments associated with a media.
 */
IB_DESIGNABLE
@interface SRGLetterboxTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

/**
 *  The timeline delegate.
 */
@property (nonatomic, weak, nullable) id<SRGLetterboxTimelineViewDelegate> delegate;

/**
 *  Reload the timeline with a new segment list.
 */
- (void)reloadWithSegments:(nullable NSArray<SRGSegment *> *)segments;

/**
 *  Update the timeline appearance for a given playback time (in seconds) and an optional segment actively selected
 *  by the user.
 */
- (void)updateAppearanceWithTime:(NSTimeInterval)timeInSeconds selectedSegment:(nullable SRGSegment *)selectedSegment;

/**
 *  Scroll the timeline to a given playback time (in seconds).
 */
- (void)scrollToTime:(NSTimeInterval)timeInSeconds animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
