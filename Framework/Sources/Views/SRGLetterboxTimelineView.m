//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimelineView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxSegmentCell.h"

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

- (void)dealloc
{
    self.controller = nil;          // Unregister everything
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxMetadataDidChangeNotification
                                                      object:_controller];
    }
    
    _controller = controller;
    [self reloadData];
    
    if (controller) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(metadataDidChange:)
                                                     name:SRGLetterboxMetadataDidChangeNotification
                                                   object:controller];
    }
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

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self reloadData];
    }
}

#pragma mark Data

- (void)reloadData
{
    NSMutableArray<SRGSegment *> *segments = [NSMutableArray array];
    
    // Show logical segments for the current chapter (if any), and display other chapters but not expanded
    SRGMediaComposition *mediaComposition = self.controller.mediaComposition;
    for (SRGChapter *chapter in mediaComposition.chapters) {
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

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self reloadData];
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
}
