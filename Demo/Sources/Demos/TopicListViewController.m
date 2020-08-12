//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TopicListViewController.h"

#import "MediaListViewController.h"
#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"
#import "TopicItem.h"
#import "UIWindow+LetterboxDemo.h"

@import SRGDataProviderNetwork;

@interface TopicListViewController ()

@property (nonatomic) TopicList topicList;
@property (nonatomic) NSURL *serviceURL;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic, weak) SRGRequest *request;

@property (nonatomic) NSArray<TopicItem *> *topicItems;

@end

@implementation TopicListViewController

#pragma mark Object lifecycle

- (instancetype)initWithTopicList:(TopicList)topicList
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.topicList = topicList;
        self.serviceURL = (self.topicList == TopicListMMF) ? LetterboxDemoMMFServiceURL() : ApplicationSettingServiceURL();
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
    
#if TARGET_OS_TV
    if (@available(tvOS 13, *)) {
        self.navigationController.tabBarObservedScrollView = self.tableView;
    }
#endif
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.serviceURL];
    self.dataProvider.globalHeaders = ApplicationSettingGlobalParameters();
    
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

- (NSString *)title
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @(TopicListSRF) : NSLocalizedString(@"SRF Topics", nil),
                      @(TopicListRTS) : NSLocalizedString(@"RTS Topics", nil),
                      @(TopicListRSI) : NSLocalizedString(@"RSI Topics", nil),
                      @(TopicListRTR) : NSLocalizedString(@"RTR Topics", nil),
                      @(TopicListSWI) : NSLocalizedString(@"SWI Topics", nil),
                      @(TopicListMMF) : NSLocalizedString(@"MMF Topics", nil) };
    });
    return s_titles[@(self.topicList)] ?: NSLocalizedString(@"Unknown", nil);
}

#pragma mark Data

- (void)refresh
{
    [self.request cancel];
    
    SRGRequest *request = [self.dataProvider tvTopicsForVendor:self.vendor withCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
#if TARGET_OS_IOS
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
#endif
        
        NSMutableArray<TopicItem *> *topicItems = NSMutableArray.new;
        for (SRGTopic *topic in topics) {
            [topicItems addObject:[[TopicItem alloc] initWitTopic:topic indentationLevel:0]];
            for (SRGTopic *subtopic in topic.subtopics) {
                [topicItems addObject:[[TopicItem alloc] initWitTopic:subtopic indentationLevel:1]];
            }
        }
        
        self.topicItems = topicItems.copy;
        [self.tableView reloadData];
    }];
    
    
    [request resume];
    self.request = request;
}

- (SRGVendor)vendor
{
    static NSDictionary<NSNumber *, NSNumber *> *s_vendors;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_vendors = @{ @(TopicListSRF) : @(SRGVendorSRF),
                       @(TopicListRTS) : @(SRGVendorRTS),
                       @(TopicListRSI) : @(SRGVendorRSI),
                       @(TopicListRTR) : @(SRGVendorRTR),
                       @(TopicListSWI) : @(SRGVendorSWI),
                       @(TopicListMMF) : @(SRGVendorRTS) };
    });
    
    NSNumber *vendorNumber = s_vendors[@(self.topicList)];
    NSAssert(vendorNumber != nil, @"The business unit must be supported");
    return vendorNumber.integerValue;
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.topicItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"TopicListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopicItem *topicItem = self.topicItems[indexPath.row];
    cell.textLabel.text = topicItem.topic.title;
    cell.indentationLevel = topicItem.indentationLevel;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopicItem *topicItem = self.topicItems[indexPath.row];
    MediaListViewController *mediaListViewController = [[MediaListViewController alloc] initWithMediaList:MediaListLatestByTopic topic:topicItem.topic serviceURL:self.serviceURL];
    [self.navigationController pushViewController:mediaListViewController animated:YES];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

@end
