//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AutoplayViewController.h"

#import "AutoplayTableViewCell.h"
#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"

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
        case AutoplayListSRFTrendingMedias: {
            self.title = LetterboxDemoNonLocalizedString(@"SRF trending videos");
            break;
        }
            
        case AutoplayListRTSTrendingMedias: {
            self.title = LetterboxDemoNonLocalizedString(@"RTS trending videos");
            break;
        }
            
        case AutoplayListRSITrendingMedias: {
            self.title = LetterboxDemoNonLocalizedString(@"RSI trending videos");
            break;
        }
            
        default: {
            self.title = nil;
            break;
        }
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
    
    SRGDataProviderBusinessUnitIdentifier businessUnitIdentifier = nil;
    switch (self.autoplayList) {
        case AutoplayListSRFTrendingMedias: {
            businessUnitIdentifier = SRGDataProviderBusinessUnitIdentifierSRF;
            break;
        }
            
        case AutoplayListRTSTrendingMedias: {
            businessUnitIdentifier = SRGDataProviderBusinessUnitIdentifierRTS;
            break;
        }
            
        case AutoplayListRSITrendingMedias: {
            businessUnitIdentifier = SRGDataProviderBusinessUnitIdentifierRSI;
            break;
        }
            
        default: {
            break;
        }
    }
    
    if (businessUnitIdentifier) {
        self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ApplicationSettingServiceURL() businessUnitIdentifier:businessUnitIdentifier];
        self.dataProvider.globalHeaders = ApplicationSettingGlobalHeaders();
        
        SRGMediaListCompletionBlock completionBlock = ^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
            self.medias = medias;
            [self.tableView reloadData];
        };
        
        SRGRequest *request = [self.dataProvider tvTrendingMediasWithLimit:@50 completionBlock:completionBlock];
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
