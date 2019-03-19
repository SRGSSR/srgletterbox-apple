//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaListViewController.h"

#import "ModalPlayerViewController.h"
#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"

@interface MediaListViewController ()

@property (nonatomic) MediaList mediaList;
@property (nonatomic) SRGTopic *topic;
@property (nonatomic, getter=isMMFOverride) BOOL MMFOverride;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic, weak) SRGBaseRequest *request;

@property (nonatomic) NSArray<SRGMedia *> *medias;

@end

@implementation MediaListViewController

#pragma mark Object lifecycle

- (instancetype)initWithMediaList:(MediaList)mediaList topic:(nullable SRGTopic *)topic MMFOverride:(BOOL)MMFOverride
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    MediaListViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.mediaList = mediaList;
    viewController.topic = topic;
    viewController.MMFOverride = MMFOverride;
    return viewController;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [self pageTitle];
    
    NSURL *serviceURL = self.MMFOverride ? LetterboxDemoMMFServiceURL() : ApplicationSettingServiceURL();
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:serviceURL];
    self.dataProvider.globalParameters = ApplicationSettingGlobalParameters();
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        [self.request cancel];
    }
}

#pragma mark Getters and setters

- (NSString *)pageTitle
{
    if (self.mediaList == MediaListLatestByTopic) {
        return self.topic.title ?: LetterboxDemoNonLocalizedString(@"Unknown");
    }
    else {
        static dispatch_once_t s_onceToken;
        static NSDictionary<NSNumber *, NSString *> *s_titles;
        dispatch_once(&s_onceToken, ^{
            s_titles = @{ @(MediaListLivecenterSRF) : LetterboxDemoNonLocalizedString(@"SRF Live center"),
                          @(MediaListLivecenterRTS) : LetterboxDemoNonLocalizedString(@"RTS Live center"),
                          @(MediaListLivecenterRSI) : LetterboxDemoNonLocalizedString(@"RSI Live center") };
        });
        return s_titles[@(self.mediaList)] ?: LetterboxDemoNonLocalizedString(@"Unknown");
    }
}

#pragma mark Data

- (void)refresh
{
    [self.request cancel];
    
    SRGBaseRequest *request = nil;
    
    SRGPaginatedMediaListCompletionBlock completionBlock = ^(NSArray<SRGMedia *> * _Nullable medias, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
        
        self.medias = medias;
        [self.tableView reloadData];
    };
    
    if (self.mediaList == MediaListLatestByTopic) {
        request = [[self.dataProvider latestMediasForTopicWithURN:self.topic.URN completionBlock:completionBlock] requestWithPageSize:100];
    }
    else {
        static NSDictionary<NSNumber *, NSNumber *> *s_vendors;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_vendors = @{ @(MediaListLivecenterSRF) : @(SRGVendorSRF),
                           @(MediaListLivecenterRTS) : @(SRGVendorRTS),
                           @(MediaListLivecenterRSI) : @(SRGVendorRSI) };
        });
        
        NSNumber *vendorNumber = s_vendors[@(self.mediaList)];
        NSAssert(vendorNumber != nil, @"The business unit must be supported");
        request = [[self.dataProvider liveCenterVideosForVendor:vendorNumber.integerValue withCompletionBlock:completionBlock] requestWithPageSize:100];
    }
    
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
    return [tableView dequeueReusableCellWithIdentifier:@"MediaListCell" forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = self.medias[indexPath.row];
    NSString *text = media.title;
    
    SRGTimeAvailability timeAvailability = [media timeAvailabilityAtDate:NSDate.date];
    if (timeAvailability == SRGTimeAvailabilityNotYetAvailable) {
        text = [@"🔜 " stringByAppendingString:text];
    }
    else if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        text = [@"🔚 " stringByAppendingString:text];
    }
    else if (media.contentType == SRGContentTypeLivestream || media.contentType == SRGContentTypeScheduledLivestream) {
        text = [@"⏺ " stringByAppendingString:text];
    }
    else {
        text = [@"▶️ " stringByAppendingString:text];
    }
    
    cell.textLabel.text = text;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *URN = self.medias[indexPath.row].URN;
    NSURL *serviceURL = self.MMFOverride ? LetterboxDemoMMFServiceURL() : nil;
    NSNumber *updateIntervalNumber = self.MMFOverride ? @(LetterboxDemoSettingUpdateIntervalShort) : nil;
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN serviceURL:serviceURL updateInterval:updateIntervalNumber];
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    
    [self presentViewController:playerViewController animated:YES completion:nil];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

@end
