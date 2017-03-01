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

@end

NS_ASSUME_NONNULL_END
