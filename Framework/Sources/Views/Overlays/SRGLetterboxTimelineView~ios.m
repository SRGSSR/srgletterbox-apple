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

static CGFloat SRGLetterboxCellMargin = 3.f;

@interface SRGLetterboxTimelineView ()

@property (nonatomic, copy) NSString *chapterURN;
@property (nonatomic) NSArray<SRGSubdivision *> *subdivisions;

@property (nonatomic, weak) UICollectionView *collectionView;

@end

static void commonInit(SRGLetterboxTimelineView *self)
{
    self.backgroundColor = UIColor.clearColor;
    self.selectedIndex = NSNotFound;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    collectionViewLayout.minimumLineSpacing = SRGLetterboxCellMargin;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.alwaysBounceHorizontal = YES;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[ [collectionView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                               [collectionView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                               [collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                               [collectionView.heightAnchor constraintEqualToConstant:120.f] ]];
    
    UINib *nib = [UINib nibWithNibName:SRGLetterboxResourceNameForUIClass(SRGLetterboxSubdivisionCell.class) bundle:NSBundle.srg_letterboxBundle];
    [collectionView registerNib:nib forCellWithReuseIdentifier:NSStringFromClass(SRGLetterboxSubdivisionCell.class)];
}

@implementation SRGLetterboxTimelineView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat height = CGRectGetHeight(self.frame) - 2 * SRGLetterboxCellMargin;
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
    if (self.collectionView.dragging) {
        return;
    }
    
    void (^animations)(void) = nil;
    
    NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    if (self.selectedIndex < numberOfItems) {
        animations = ^{
            // Force layout so that scrolling to an item works
            [self setNeedsLayout];
            [self layoutIfNeeded];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
        };
    }
    else if (self.controller.live) {
        if (numberOfItems != 0) {
            animations = ^{
                // Force layout so that scrolling to an item works
                [self setNeedsLayout];
                [self layoutIfNeeded];
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:numberOfItems - 1 inSection:0]
                                            atScrollPosition:UICollectionViewScrollPositionRight
                                                    animated:NO];
            };
        }
        else {
            return;
        }
    }
    else {
        return;
    }
    
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

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(SRGLetterboxCellMargin, SRGLetterboxCellMargin, SRGLetterboxCellMargin, SRGLetterboxCellMargin);
}

@end
