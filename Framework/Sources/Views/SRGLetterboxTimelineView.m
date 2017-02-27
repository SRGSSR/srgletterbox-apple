//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimelineView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxSegmentCell.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>

static void commonInit(SRGLetterboxTimelineView *self);

@interface SRGLetterboxTimelineView ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSArray<SRGSegment *> *segments;

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

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.collectionView.alwaysBounceHorizontal = YES;
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    collectionViewLayout.minimumLineSpacing = 1.f;
    collectionViewLayout.itemSize = CGSizeMake(160.f, 130.f);
    
    NSString *identifier = NSStringFromClass([SRGLetterboxSegmentCell class]);
    UINib *nib = [UINib nibWithNibName:identifier bundle:[NSBundle srg_letterboxBundle]];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

#pragma mark Data

- (void)reloadWithMediaComposition:(SRGMediaComposition *)mediaComposition
{
    NSMutableArray<SRGSegment *> *segments = [NSMutableArray array];
    
    // Show logical segments for the current chapter (if any), and display other chapters but not expanded
    for (SRGChapter *chapter in mediaComposition.chapters) {
        // TODO: Visible segments only
        if (chapter == mediaComposition.mainChapter && chapter.segments.count != 0) {
            [segments addObjectsFromArray:chapter.segments];
        }
        else {
            [segments addObject:chapter];
        }
    }
    self.segments = [segments copy];
    
    [self.collectionView reloadData];
}

#pragma mark UI

- (void)updateAppearanceWithTime:(CMTime)time selectedSegment:(SRGSegment *)selectedSegment
{
    for (SRGLetterboxSegmentCell *cell in self.collectionView.visibleCells) {
        [cell updateAppearanceWithTime:time selectedSegment:selectedSegment];
    }
}

- (void)scrollToTime:(CMTime)time animated:(BOOL)animated
{
    if (CMTIME_IS_INVALID(time)) {
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGSegment * _Nonnull segment, NSDictionary<NSString *, id> *_Nullable bindings) {
        Float64 timeInSeconds = CMTimeGetSeconds(time);
        return segment.markIn / 1000. <= timeInSeconds && timeInSeconds <= segment.markOut / 1000.;
    }];
    
    SRGSegment *segment = [self.segments filteredArrayUsingPredicate:predicate].firstObject;
    if (! segment) {
        return;
    }
    
    NSInteger segmentIndex = [self.segments indexOfObject:segment];
    
    void (^animations)(void) = ^{
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:segmentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    };
    
    if (animated) {
        // Override the standard scroll to item animation duration for faster snapping
        [UIView animateWithDuration:0.1 animations:animations];
    }
    else {
        animations();
    }
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.segments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGLetterboxSegmentCell *segmentCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SRGLetterboxSegmentCell class]) forIndexPath:indexPath];
    segmentCell.segment = self.segments[indexPath.row];
    return segmentCell;
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate timelineView:self didSelectSegment:self.segments[indexPath.row]];
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
    
    self.backgroundColor = [UIColor clearColor];
}
