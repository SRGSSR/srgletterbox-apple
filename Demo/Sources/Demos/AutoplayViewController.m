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

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic, weak) SRGRequest *request;

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

#pragma mark Setters

- (void)setAutoplayList:(AutoplayList)autoplayList
{
    _autoplayList = autoplayList;
    
    switch (autoplayList) {
        case AutoplayListRTSTrendingMedias:
            self.title = @"RTS trending videos";
            break;
        case AutoplayListSRFLiveCenterVideos:
            self.title = @"SRF live center videos";
            break;
        case AutoplayListRTSLiveCenterVideos:
            self.title = @"RTS live center videos";
            break;
        case AutoplayListRSILiveCenterVideos:
            self.title = @"RSI live center videos";
            break;
        default:
            self.title = nil;
            break;
    }
    
    if (self.viewLoaded) {
        [self refresh];
    }
}

#pragma mark Data

- (void)refresh
{
    [self.request cancel];
    self.request = nil;
    
    self.medias = nil;
    [self.tableView reloadData];
    
    SRGDataProviderBusinessUnitIdentifier buIdentifier = nil;
    switch (self.autoplayList) {
        case AutoplayListRTSTrendingMedias:
        case AutoplayListRTSLiveCenterVideos:
            buIdentifier = SRGDataProviderBusinessUnitIdentifierRTS;
            break;
        case AutoplayListSRFLiveCenterVideos:
            buIdentifier = SRGDataProviderBusinessUnitIdentifierSRF;
             break;
        case AutoplayListRSILiveCenterVideos:
            buIdentifier = SRGDataProviderBusinessUnitIdentifierRSI;
            break;
        default:
            break;
    }
    
    if (buIdentifier) {
        self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL() businessUnitIdentifier:buIdentifier];
        
        SRGPaginatedMediaListCompletionBlock completionBlock = ^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
            self.medias = medias;
            [self.tableView reloadData];
        };
        
        SRGRequest *request = nil;
        switch (self.autoplayList) {
            case AutoplayListRTSTrendingMedias:
                request = [self.dataProvider tvTrendingMediasWithCompletionBlock:completionBlock];
                break;
            case AutoplayListSRFLiveCenterVideos:
            case AutoplayListRTSLiveCenterVideos:
            case AutoplayListRSILiveCenterVideos:
                request = [self.dataProvider livecenterVideoScheduledLivestreamsWithCompletionBlock:completionBlock];
                break;
                
            default:
                break;
        }
        
        [request resume];
        self.request = request;
    }
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
