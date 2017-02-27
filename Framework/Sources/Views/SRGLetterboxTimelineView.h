//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxTimelineView;

@protocol SRGLetterboxTimelineViewDelegate <NSObject>

- (void)timelineView:(SRGLetterboxTimelineView *)timelineView didSelectSegment:(SRGSegment *)segment;

@end

IB_DESIGNABLE
@interface SRGLetterboxTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak, nullable) id<SRGLetterboxTimelineViewDelegate> delegate;

- (void)reloadWithMediaComposition:(nullable SRGMediaComposition *)mediaComposition;

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(nullable SRGSegment *)selectedSegment;

- (void)scrollToTime:(CMTime)time animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
