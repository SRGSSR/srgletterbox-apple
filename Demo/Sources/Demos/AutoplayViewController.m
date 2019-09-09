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
#import <SRGLetterbox/SRGLetterbox.h>

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
    
    // Allow other applications to play audios, as the view starts only wih muted videos.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:NULL];
    
    [self refresh];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        [self.request cancel];
        
        if ([AVAudioSession sharedInstance].categoryOptions != 0) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:NULL];
        }
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
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ApplicationSettingServiceURL()];
    self.dataProvider.globalParameters = ApplicationSettingGlobalParameters();
    
    SRGMediaListCompletionBlock completionBlock = ^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        self.medias = medias;
        [self.tableView reloadData];
    };
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_vendors;
    dispatch_once(&s_onceToken, ^{
        s_vendors = @{ @(AutoplayListRSITrendingMedias) : @(SRGVendorRSI),
                       @(AutoplayListRTSTrendingMedias) : @(SRGVendorRTS),
                       @(AutoplayListSRFTrendingMedias) : @(SRGVendorSRF) };
    });
    
    SRGVendor vendor = [s_vendors[@(self.autoplayList)] integerValue];
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
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_localizations;
    dispatch_once(&s_onceToken, ^{
        s_localizations = @{ @(AutoplayListRSITrendingMedias) : @"it",
                             @(AutoplayListRTSTrendingMedias) : @"fr",
                             @(AutoplayListSRFTrendingMedias) : @"de" };
    });
    
    [cell setMedia:self.medias[indexPath.row] withPreferredSubtitleLocalization:s_localizations[@(self.autoplayList)]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([AVAudioSession sharedInstance].categoryOptions != 0) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:NULL];
    }
    
    AutoplayTableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.muted = ! selectedCell.muted;
    
    [tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof AutoplayTableViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if (! [cell isEqual:selectedCell]) {
            cell.muted = YES;
        }
    }];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(AutoplayTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setMedia:nil withPreferredSubtitleLocalization:nil];
    
    if (cell.selected) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetWidth(tableView.frame) * 9.f / 16.f;
}

@end
