//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimelineView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxSubdivisionCell.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>
#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static void commonInit(SRGLetterboxTimelineView *self);

@interface SRGLetterboxTimelineView ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation SRGLetterboxTimelineView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

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

- (void)setNeedsSubdivisionsFavoritesUpdate
{
    [self.collectionView reloadData];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.collectionView.alwaysBounceHorizontal = YES;
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    collectionViewLayout.minimumLineSpacing = 1.f;
    
    NSString *identifier = NSStringFromClass([SRGLetterboxSubdivisionCell class]);
    UINib *nib = [UINib nibWithNibName:identifier bundle:[NSBundle srg_letterboxBundle]];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat height = CGRectGetHeight(self.frame);
    collectionViewLayout.itemSize = CGSizeMake(16.f / 13.f * height, height);
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChange:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIContentSizeCategoryDidChangeNotification
                                                      object:nil];
    }
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
    
    // Do not display progress for chapters
    if (! [subdivision isKindOfClass:[SRGChapter class]]) {
        // Clamp progress so that past subdivisions have progress = 1 and future ones have progress = 0
        float progress = CMTimeGetSeconds(CMTimeSubtract(self.time, subdivision.srg_timeRange.start)) / CMTimeGetSeconds(subdivision.srg_timeRange.duration);
        cell.progress = fminf(1.f, fmaxf(0.f, progress));
    }
    else {
        cell.progress = 0.f;
    }
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
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
        }
    };
    
    if (animated) {
        // Override the standard scroll to item animation duration for faster snapping
        [UIView animateWithDuration:0.1 animations:animations completion:nil];
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
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SRGLetterboxSubdivisionCell class]) forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGSubdivision *subdivision = self.subdivisions[indexPath.row];
    [self.delegate letterboxTimelineView:self didSelectSubdivision:subdivision];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(SRGLetterboxSubdivisionCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    cell.subdivision = self.subdivisions[indexPath.row];
    [self updateAppearanceForCell:cell];
}

#pragma mark Notifications

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

@end

static void commonInit(SRGLetterboxTimelineView *self)
{
    // This makes design in a xib and Interface Builder preview (IB_DESIGNABLE) work. The top-level view must NOT be
    // an SRGLetterboxTimelineView to avoid infinite recursion
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.selectedIndex = NSNotFound;
    self.backgroundColor = [UIColor clearColor];
}
