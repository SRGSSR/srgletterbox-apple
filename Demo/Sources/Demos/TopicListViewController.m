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

#import <SRGDataProvider/SRGDataProvider.h>

@interface TopicListViewController ()

@property (nonatomic) TopicList topicList;

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic, weak) SRGRequest *request;

@property (nonatomic) NSArray<TopicItem *> *topicItems;

@end

@implementation TopicListViewController

#pragma mark Object lifecycle

- (instancetype)initWithTopicList:(TopicList)topicList
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    TopicListViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.topicList = topicList;
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
    
    NSURL *serviceURL = (self.topicList == TopicListMMF) ? LetterboxDemoMMFServiceURL() : ApplicationSettingServiceURL();
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:serviceURL];
    self.dataProvider.globalHeaders = ApplicationSettingGlobalHeaders();
        
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    [self.refreshControl beginRefreshing];
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        [self.request cancel];
    }
}

#pragma mark Getters and setters

- (NSString *)pageTitle
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @(TopicListSRF) : LetterboxDemoNonLocalizedString(@"SRF Topics"),
                      @(TopicListRTS) : LetterboxDemoNonLocalizedString(@"RTS Topics"),
                      @(TopicListRSI) : LetterboxDemoNonLocalizedString(@"RSI Topics"),
                      @(TopicListRTR) : LetterboxDemoNonLocalizedString(@"RTR Topics"),
                      @(TopicListMMF) : LetterboxDemoNonLocalizedString(@"MMF Topics") };
    });
    return s_titles[@(self.topicList)] ?: LetterboxDemoNonLocalizedString(@"Unknown");
}

#pragma mark Data

- (void)refresh
{
    [self.request cancel];
    
    [self.refreshControl beginRefreshing];
    SRGRequest *request = [self.dataProvider tvTopicsForVendor:self.vendor withCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSError * _Nullable error) {
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
        
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
    return [tableView dequeueReusableCellWithIdentifier:@"TopicListCell" forIndexPath:indexPath];
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
    MediaListViewController *mediaListViewController = [[MediaListViewController alloc] initWithMediaList:MediaListLatestByTopic topic:topicItem.topic MMFOverride:(self.topicList == TopicListMMF)];
    [self.navigationController pushViewController:mediaListViewController animated:YES];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

@end
