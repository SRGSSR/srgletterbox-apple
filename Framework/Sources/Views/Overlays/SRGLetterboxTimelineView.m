//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimelineView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxView+Private.h"
#import "SRGLetterboxSubdivisionCell.h"
#import "SRGMediaComposition+SRGLetterbox.h"

@interface SRGLetterboxTimelineView ()

@property (nonatomic, copy) NSString *chapterURN;
@property (nonatomic) NSArray<SRGSubdivision *> *subdivisions;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation SRGLetterboxTimelineView

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

- (void)setNeedsSubdivisionFavoritesUpdate
{
    [self.collectionView reloadData];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.selectedIndex = NSNotFound;
    self.backgroundColor = UIColor.clearColor;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.collectionView.alwaysBounceHorizontal = YES;
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    collectionViewLayout.minimumLineSpacing = 1.f;
    
    NSString *identifier = NSStringFromClass(SRGLetterboxSubdivisionCell.class);
    UINib *nib = [UINib nibWithNibName:identifier bundle:NSBundle.srg_letterboxBundle];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat height = CGRectGetHeight(self.frame);
    CGFloat width = (height > 0) ? 16.f / 13.f * height : 10e-6f; // UICollectionViewFlowLayout doesn't allow CGSizeZero
    collectionViewLayout.itemSize = CGSizeMake(width, height);
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    [self.collectionView reloadData];
}

- (void)metadataDidChange
{
    [super metadataDidChange];
    
    SRGMediaComposition *mediaComposition = self.controller.mediaComposition;
    SRGSubdivision *subdivision = (SRGSegment *)self.controller.mediaPlayerController.currentSegment ?: mediaComposition.mainSegment ?: mediaComposition.mainChapter;
    
    self.chapterURN = mediaComposition.mainChapter.URN;
    self.subdivisions = mediaComposition.srgletterbox_subdivisions;
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
            progress = (1000. * CMTimeGetSeconds(self.time) - segment.markIn) / segment.duration;
        }
    }
    cell.progress = fminf(1.f, fmaxf(0.f, progress));
}

#pragma mark Scrolling

- (void)scrollToSelectedIndexAnimated:(BOOL)animated
{
    if (self.selectedIndex == NSNotFound) {
        return;
    }
    
    if (self.collectionView.dragging) {
        return;
    }
    
    void (^animations)(void) = ^{
        if (self.selectedIndex < [self.collectionView numberOfItemsInSection:0]) {
            [self layoutIfNeeded];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
        }
    };
    
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
}

#pragma mark SRGLetterboxSubdivisionCellDelegate protocol

- (void)letterboxSubdivisionCellDidLongPress:(SRGLetterboxSubdivisionCell *)letterboxSubdivisionCell
{
    [self.delegate letterboxTimelineView:self didLongPressSubdivision:letterboxSubdivisionCell.subdivision];
}

- (BOOL)letterboxSubdivisionCellShouldDisplayFavoriteIcon:(SRGLetterboxSubdivisionCell *)letterboxSubdivisionCell
{
    return [self.delegate letterboxTimelineView:self shouldDisplayFavoriteForSubdivision:letterboxSubdivisionCell.subdivision];
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
            self.time = CMTimeMakeWithSeconds(segment.markIn / 1000., NSEC_PER_SEC);
        }
        else {
            self.chapterURN = subdivision.URN;
            self.time = kCMTimeZero;
        }
        self.selectedIndex = [self.subdivisions indexOfObject:subdivision];
        [self scrollToSelectedIndexAnimated:YES];
    }
    
    [self.delegate letterboxTimelineView:self didSelectSubdivision:subdivision];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(SRGLetterboxSubdivisionCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    cell.subdivision = self.subdivisions[indexPath.row];
    [self updateAppearanceForCell:cell];
}

@end
