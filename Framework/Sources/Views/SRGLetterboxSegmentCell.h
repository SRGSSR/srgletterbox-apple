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
 *  Letterbox segment cell delegate protocol for options custom status
 */
@protocol SRGLetterboxSegmentCellDelegate <NSObject>

@optional

/**
 *  This method gets called when the user makes a long press on a segment cell
 *  By defaut, if non implemented, return NO.
 */
- (BOOL)letterboxSegmentCellShouldRecognizeLongPress:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

/**
 *  This method gets called when the user interface made a long press on segment cell
 */
- (void)letterboxSegmentCellLongPressRecognized:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

/**
 *  This method gets called when the user interface is about to being displayed.
 *  By defaut, if non implemented, return YES.
 */
- (BOOL)letterboxSegmentCellShouldHideCustomStatusImage:(SRGLetterboxSegmentCell *)letterboxSegmentCell;

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
@property (nonatomic, getter=isHiddenCustomStatus) BOOL hiddenCustomStatus;

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGLetterboxSegmentCellDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
