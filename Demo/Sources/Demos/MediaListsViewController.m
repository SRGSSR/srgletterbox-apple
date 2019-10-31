//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaListsViewController.h"

#import "MediaListViewController.h"
#import "TopicListViewController.h"

@implementation MediaListsViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Lists", nil);
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        s_rows = @[ @6,
                    @3 ];
    });
    return s_rows[section].integerValue;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ NSLocalizedString(@"Topics", nil),
                      NSLocalizedString(@"Live center", nil) ];
    });
    return s_titles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"BasicCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

#pragma mark Lists

- (void)openTopicListWithType:(TopicList)topicList
{
    TopicListViewController *topicListViewController = [[TopicListViewController alloc] initWithTopicList:topicList];
    [self.navigationController pushViewController:topicListViewController animated:YES];
}

- (void)openMediaListWithType:(MediaList)mediaList
{
    MediaListViewController *mediaListViewController = [[MediaListViewController alloc] initWithMediaList:mediaList topic:nil serviceURL:nil];
    [self.navigationController pushViewController:mediaListViewController animated:YES];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSArray<NSString *> *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ @[ NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil),
                         NSLocalizedString(@"RTR", nil),
                         NSLocalizedString(@"SWI", nil),
                         NSLocalizedString(@"Play MMF", nil) ],
                      @[ NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil) ] ];
    });
    cell.textLabel.text = s_titles[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_topics;
            dispatch_once(&s_onceToken, ^{
                s_topics = @[ @(TopicListSRF),
                              @(TopicListRTS),
                              @(TopicListRSI),
                              @(TopicListRTR),
                              @(TopicListSWI),
                              @(TopicListMMF) ];
            });
            [self openTopicListWithType:s_topics[indexPath.row].integerValue];
            break;
        }
            
        case 1: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLiveCenterSRF),
                             @(MediaListLiveCenterRTS),
                             @(MediaListLiveCenterRSI) ];
            });
            [self openMediaListWithType:s_lists[indexPath.row].integerValue];
            break;
        }
            
        default: {
            break;
        }
    }
}

@end
