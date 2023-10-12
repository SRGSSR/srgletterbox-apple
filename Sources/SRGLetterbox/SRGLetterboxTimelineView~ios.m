//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGLetterboxTimelineView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxView+Private.h"
#import "SRGLetterboxSubdivisionCell.h"
#import "SRGMediaComposition+SRGLetterbox.h"

@import libextobjc;
@import MAKVONotificationCenter;

static const CGFloat SRGLetterboxCellMargin = 3.f;

@interface SRGLetterboxTimelineView ()

@property (nonatomic, copy) NSString *chapterURN;
@property (nonatomic) NSArray<SRGSubdivision *> *subdivisions;

@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation SRGLetterboxTimelineView

#pragma mark Layout

- (void)layoutContentView
{
    [super layoutContentView];
    
    self.contentView.backgroundColor = UIColor.clearColor;
    self.selectedIndex = NSNotFound;
    
    self.contentView.clipsToBounds = YES;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    collectionViewLayout.minimumLineSpacing = SRGLetterboxCellMargin;
    CGFloat height = SRGLetterboxTimelineViewDefaultHeight - 2 * SRGLetterboxCellMargin;
    NSAssert(height > 0.f, @"Height must be positive");
    collectionViewLayout.itemSize = CGSizeMake(16.f / 13.f * height, height);

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.contentView.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.alwaysBounceHorizontal = YES;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self.contentView addSubview:collectionView];
    self.collectionView = collectionView;
    
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [collectionView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [collectionView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [collectionView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [collectionView.heightAnchor constraintEqualToConstant:SRGLetterboxTimelineViewDefaultHeight]
    ]];
    
    Class cellClass = SRGLetterboxSubdivisionCell.class;
    [collectionView registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(SRGLetterboxSubdivisionCell.class)];
}

#pragma mark Getters and setters

- (void)setChapterURN:(NSString *)chapterURN
{
    _chapterURN = chapterURN;
    [self updateCellAppearance];
}

- (void)setSubdivisions:(NSArray<SRGSubdivision *> *)subdivisions
{
    _subdivisions = subdivisions;
    [self.collectionView reloadData];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (selectedIndex >= self.subdivisions.count) {
        selectedIndex = NSNotFound;
    }
    
    _selectedIndex = selectedIndex;
    [self updateCellAppearance];
}

- (void)setTime:(CMTime)time
{
    _time = time;
    [self updateCellAppearance];
}

#pragma mark Overrides

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    [self.collectionView reloadData];
}

- (void)metadataDidChange
{
    [super metadataDidChange];
    
    [self reloadSubdivisions];
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    [mediaPlayerController removeObserver:self keyPath:@keypath(mediaPlayerController.timeRange)];
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    [mediaPlayerController addObserver:self keyPath:@keypath(mediaPlayerController.timeRange) options:0 block:^(MAKVONotification * _Nonnull notification) {
        [self reloadSubdivisions];
    }];
    [self reloadSubdivisions];
}

- (void)reloadSubdivisions
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    SRGMediaComposition *mediaComposition = self.controller.mediaComposition;
    SRGSubdivision *subdivision = (SRGSegment *)mediaPlayerController.currentSegment ?: mediaComposition.mainSegment ?: mediaComposition.mainChapter;
    
    self.chapterURN = mediaComposition.mainChapter.URN;
    self.subdivisions = [mediaComposition srgletterbox_subdivisionsForMediaPlayerController:mediaPlayerController];
    self.selectedIndex = subdivision ? [self.subdivisions indexOfObject:subdivision] : NSNotFound;
}

#pragma mark Cell appearance

// We must not call -reloadData to update cells when not necessary (this invalidates taps)
// Also see http://stackoverflow.com/questions/23940419/uicollectionview-cell-cant-be-selected-after-reload-in-case-if-cell-was-touched
- (void)updateCellAppearance
{
    for (SRGLetterboxSubdivisionCell *cell in self.collectionView.visibleCells) {
        [self updateAppearanceForCell:cell];
    }
}

- (void)updateAppearanceForCell:(SRGLetterboxSubdivisionCell *)cell
{
    SRGSubdivision *subdivision = cell.subdivision;
    
    NSUInteger index = [self.subdivisions indexOfObject:subdivision];
    cell.current = (index == self.selectedIndex);
    
    float progress = 0.f;
    
    if (self.chapterURN) {
        if ([subdivision isKindOfClass:SRGChapter.class] && [subdivision.URN isEqual:self.chapterURN]) {
            progress = 1000. * CMTimeGetSeconds(self.time) / subdivision.duration;
        }
        else if ([subdivision isKindOfClass:SRGSegment.class] && [subdivision.fullLengthURN isEqual:self.chapterURN]) {
            SRGSegment *segment = (SRGSegment *)subdivision;
            CMTimeRange segmentTimeRange = [segment.srg_markRange srg_timeRangeForLetterboxController:self.controller];
            progress = (CMTimeGetSeconds(self.time) - CMTimeGetSeconds(segmentTimeRange.start)) / (CMTimeGetSeconds(segmentTimeRange.duration));
        }
    }
    cell.progress = fminf(1.f, fmaxf(0.f, progress));
}

#pragma mark Scrolling

- (void)scrollToCurrentSelectionAnimated:(BOOL)animated
{
    if (self.collectionView.dragging) {
        return;
    }
    
    void (^animations)(void) = nil;
    
    if (self.selectedIndex != NSNotFound) {
        animations = ^{
            NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
            if (self.selectedIndex < numberOfItems) {
                @try {
                    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]
                                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                        animated:NO];
                }
                @catch (NSException *exception) {}
            }
        };
    }
    else if (self.subdivisions.count != 0) {
        CMTime time = self.time;
        if (CMTIME_IS_INVALID(time) || CMTIME_IS_INDEFINITE(time)) {
            return;
        }
        
        // Here is how the nearest index is determined with 3 disjoint subdivisions as example:
        //
        //         ┌─────────────────────────────────┐           ┌──────────────────┐         ┌───────────────────────────────┐
        //─────────┤                0                ├───────────┤        1         ├─────────┤               2               ├────────────  time
        //         └─────────────────────────────────┘           └──────────────────┘         └───────────────────────────────┘
        // ◀─────────────────────────────────────────────────────▶◀───────────────────────────▶◀──────────────────────────────────────────▶
        //                      nearest = 0                                 nearest = 1                       nearest = 2
        //
        __block NSUInteger nearestIndex = 0;
        [self.subdivisions enumerateObjectsUsingBlock:^(SRGSubdivision * _Nonnull subdivision, NSUInteger idx, BOOL * _Nonnull stop) {
            if (! [subdivision isKindOfClass:SRGSegment.class]) {
                return;
            }
            
            SRGSegment *segment = (SRGSegment *)subdivision;
            CMTime segmentStartTime = [segment.srg_markRange srg_timeRangeForLetterboxController:self.controller].start;
            if (CMTIME_COMPARE_INLINE(time, <, segmentStartTime)) {
                nearestIndex = (idx > 0) ? idx - 1 : 0;
                *stop = YES;
            }
            else {
                // Last segment
                nearestIndex = idx;
            }
        }];
        
        animations = ^{
            @try {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:nearestIndex inSection:0]
                                            atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                    animated:NO];
            }
            @catch (NSException *exception) {}
        };
    }
    else {
        return;
    }
    
    // Schedule for next run loop so that scrolling works and its animation is performed separately
    dispatch_async(dispatch_get_main_queue(), ^{
        if (animated) {
            // Override the standard scroll to item animation duration for faster snapping
            [self layoutIfNeeded];
            [UIView animateWithDuration:0.1 animations:^{
                animations();
                [self layoutIfNeeded];
            } completion:nil];
        }
        else {
            animations();
        }
    });
}

#pragma mark SRGLetterboxSubdivisionCellDelegate protocol

- (void)letterboxSubdivisionCellDidLongPress:(SRGLetterboxSubdivisionCell *)letterboxSubdivisionCell
{
    [self.delegate letterboxTimelineView:self didLongPressSubdivision:letterboxSubdivisionCell.subdivision];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.subdivisions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SRGLetterboxSubdivisionCell.class) forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGSubdivision *subdivision = self.subdivisions[indexPath.row];
    
    if ([self.controller switchToSubdivision:subdivision withCompletionHandler:nil]) {
        if ([subdivision isKindOfClass:SRGSegment.class]) {
            SRGSegment *segment = (SRGSegment *)subdivision;
            self.time = [segment.srg_markRange srg_timeRangeForLetterboxController:self.controller].start;
        }
        else {
            self.chapterURN = subdivision.URN;
            self.time = kCMTimeZero;
        }
        self.selectedIndex = [self.subdivisions indexOfObject:subdivision];
        [self scrollToCurrentSelectionAnimated:YES];
    }
    
    [self.delegate letterboxTimelineView:self didSelectSubdivision:subdivision];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(SRGLetterboxSubdivisionCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    [cell setSubdivision:self.subdivisions[indexPath.row] controller:self.controller];
    [self updateAppearanceForCell:cell];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(SRGLetterboxCellMargin, SRGLetterboxCellMargin, SRGLetterboxCellMargin, SRGLetterboxCellMargin);
}

@end

#endif
