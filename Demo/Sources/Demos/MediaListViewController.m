//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaListViewController.h"

#import "ModalPlayerViewController.h"
#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"
#import "UIViewController+LetterboxDemo.h"

@interface MediaListViewController ()

@property (nonatomic) MediaList mediaList;
@property (nonatomic) SRGTopic *topic;
@property (nonatomic) NSURL *serviceURL;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic, weak) SRGBaseRequest *request;

@property (nonatomic) NSArray<SRGMedia *> *medias;

@end

@implementation MediaListViewController

#pragma mark Object lifecycle

- (instancetype)initWithMediaList:(MediaList)mediaList topic:(SRGTopic *)topic serviceURL:(NSURL *)serviceURL
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.mediaList = mediaList;
        self.topic = topic;
        self.serviceURL = serviceURL;
    }
    return self;
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
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.title = [self pageTitle];
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.serviceURL ?: ApplicationSettingServiceURL()];
    self.dataProvider.globalParameters = ApplicationSettingGlobalParameters();
    
#if TARGET_OS_IOS
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
#endif
    
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
        return self.topic.title ?: NSLocalizedString(@"Unknown", nil);
    }
    else {
        static dispatch_once_t s_onceToken;
        static NSDictionary<NSNumber *, NSString *> *s_titles;
        dispatch_once(&s_onceToken, ^{
            s_titles = @{ @(MediaListLiveCenterSRF) : NSLocalizedString(@"SRF Live center", nil),
                          @(MediaListLiveCenterRTS) : NSLocalizedString(@"RTS Live center", nil),
                          @(MediaListLiveCenterRSI) : NSLocalizedString(@"RSI Live center", nil) };
        });
        return s_titles[@(self.mediaList)] ?: NSLocalizedString(@"Unknown", nil);
    }
}

#pragma mark Data

- (void)refresh
{
    [self.request cancel];
    
    SRGBaseRequest *request = nil;
    
    SRGPaginatedMediaListCompletionBlock completionBlock = ^(NSArray<SRGMedia *> * _Nullable medias, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
#if TARGET_OS_IOS
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
#endif
        
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
            s_vendors = @{ @(MediaListLiveCenterSRF) : @(SRGVendorSRF),
                           @(MediaListLiveCenterRTS) : @(SRGVendorRTS),
                           @(MediaListLiveCenterRSI) : @(SRGVendorRSI) };
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
    static NSString * const kCellIdentifier = @"MediaListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
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
    [self openPlayerWithURN:URN serviceURL:self.serviceURL];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

@end
