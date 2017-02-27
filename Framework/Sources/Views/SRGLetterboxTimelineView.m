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

- (void)reloadWithSegments:(NSArray<SRGSegment *> *)segments
{
    self.segments = segments;
    [self.collectionView reloadData];
}

#pragma mark UI

- (void)updateAppearanceWithTime:(NSTimeInterval)timeInSeconds currentSegment:(SRGSegment *)currentSegment
{
    for (SRGLetterboxSegmentCell *cell in self.collectionView.visibleCells) {
        [cell updateAppearanceWithTime:timeInSeconds currentSegment:currentSegment];
    }
}

- (void)scrollToTime:(NSTimeInterval)timeInSeconds withCurrentSegment:(SRGSegment *)currentSegment animated:(BOOL)animated
{
    // Try to locate a segment whose parent is the current segment (if any) and matching the specified time
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGSegment * _Nonnull segment, NSDictionary<NSString *, id> *_Nullable bindings) {
        return [segment.fullLengthURN isEqual:currentSegment.URN] && segment.markIn / 1000. <= timeInSeconds && timeInSeconds <= segment.markOut / 1000.;
    }];
    
    // Use the current segment as fallback
    SRGSegment *segment = [self.segments filteredArrayUsingPredicate:predicate].firstObject ?: currentSegment;
    NSInteger segmentIndex = [self.segments indexOfObject:segment];
    if (segmentIndex == NSNotFound) {
        return;
    }
    
    void (^animations)(void) = ^{
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:segmentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished) {
            // -scrollViewDidScroll is not called when scrolling programatically. Call it manually for consistent behavior
            [self scrollViewDidScroll:self.collectionView];
        }
    };
    
    if (animated) {
        // Override the standard scroll to item animation duration for faster snapping
        [UIView animateWithDuration:0.1 animations:animations completion:completion];
    }
    else {
        animations();
        completion(YES);
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
    SRGSegment *segment = self.segments[indexPath.row];
    [self.delegate timelineView:self didSelectSegment:segment];
    [self scrollToTime:segment.markIn / 1000. withCurrentSegment:segment animated:YES];
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.delegate timelineViewDidScroll:self];
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
