//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AutoplayViewController.h"

#import "AutoplayTableViewCell.h"

#import <SRGDataProvider/SRGDataProvider.h>

@interface AutoplayViewController ()

@property (nonatomic) NSArray<SRGMedia *> *medias;
@property (nonatomic) SRGRequest *request;

@end

@implementation AutoplayViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self refresh];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        [self.request cancel];
    }
}

#pragma mark Data

- (void)refresh
{
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRTS];
    self.request = [[dataProvider tvTrendingMediasWithCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
        self.medias = medias;
        [self.tableView reloadData];
    }] withPageSize:50];
    [self.request resume];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.medias.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AutoplayTableViewCell class])];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(AutoplayTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.media = self.medias[indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetWidth(tableView.frame) * 9.f / 16.f;
}

@end
