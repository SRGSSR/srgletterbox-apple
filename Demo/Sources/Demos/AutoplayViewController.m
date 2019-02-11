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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
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
    
    if (self.movingFromParentViewController || self.beingDismissed) {
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
    
    SRGVendor vendor = SRGVendorNone;
    switch (self.autoplayList) {
        case AutoplayListSRFTrendingMedias: {
            vendor = SRGVendorSRF;
            break;
        }
            
        case AutoplayListRTSTrendingMedias: {
            vendor = SRGVendorRTS;
            break;
        }
            
        case AutoplayListRSITrendingMedias: {
            vendor = SRGVendorRSI;
            break;
        }
            
        default: {
            return;
            break;
        }
    }
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ApplicationSettingServiceURL()];
    self.dataProvider.globalParameters = ApplicationSettingGlobalParameters();
    
    SRGMediaListCompletionBlock completionBlock = ^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        self.medias = medias;
        [self.tableView reloadData];
    };
    
    SRGRequest *request = [self.dataProvider tvTrendingMediasForVendor:vendor withLimit:@50 completionBlock:completionBlock];
    [request resume];
    self.request = request;
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.medias.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(AutoplayTableViewCell.class)];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(AutoplayTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.media = self.medias[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(AutoplayTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.media = nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetWidth(tableView.frame) * 9.f / 16.f;
}

@end
