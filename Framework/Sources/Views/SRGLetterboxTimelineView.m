//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxTimelineView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxSegmentCell.h"

#import <Masonry/Masonry.h>

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

- (void)setController:(SRGLetterboxController *)controller
{
    _controller = controller;
    [self reloadData];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.collectionView.alwaysBounceHorizontal = YES;
    
    NSString *identifier = NSStringFromClass([SRGLetterboxSegmentCell class]);
    UINib *nib = [UINib nibWithNibName:identifier bundle:nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self reloadData];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat height = CGRectGetHeight(self.collectionView.frame);
    collectionViewLayout.itemSize = CGSizeMake(16.f / 9.f * height, height);
    [collectionViewLayout invalidateLayout];
}

#pragma mark Data

- (void)reloadData
{
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.controller.mediaPlayerController.visibleSegments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SRGLetterboxSegmentCell class]) forIndexPath:indexPath];
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
