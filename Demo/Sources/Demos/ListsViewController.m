//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ListsViewController.h"

#import "MediaListViewController.h"
#import "TopicListViewController.h"

@implementation ListsViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if TARGET_OS_TV
    if (@available(tvOS 13, *)) {
        self.navigationController.tabBarObservedScrollView = self.tableView;
    }
#endif
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        s_rows = @[ @6,
                    @4,
                    @4,
                    @6,
                    @4,
                    @5,
                    @15 ];
    });
    return s_rows[section].integerValue;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ NSLocalizedString(@"📚 Topics TV", nil),
                      NSLocalizedString(@"📺 Live TV", nil),
                      NSLocalizedString(@"📻 Live radio", nil),
                      NSLocalizedString(@"🎳 Live center", nil),
                      NSLocalizedString(@"🛰️ Live web", nil),
                      NSLocalizedString(@"🎬 Latest videos", nil),
                      NSLocalizedString(@"🔊 Latest audios", nil) ];
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
        s_titles = @[ @[ NSLocalizedString(@"Play MMF", nil),
                         NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil),
                         NSLocalizedString(@"RTR", nil),
                         NSLocalizedString(@"SWI", nil) ],
                      @[ NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil),
                         NSLocalizedString(@"RTR", nil) ],
                      @[ NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil),
                         NSLocalizedString(@"RTR", nil) ],
                      @[ NSLocalizedString(@"SRF (with result)", nil),
                         NSLocalizedString(@"SRF (all)", nil),
                         NSLocalizedString(@"RTS (with result)", nil),
                         NSLocalizedString(@"RTS (all)", nil),
                         NSLocalizedString(@"RSI (with result)", nil),
                         NSLocalizedString(@"RSI (all)", nil) ],
                      @[ NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil),
                         NSLocalizedString(@"RTR", nil) ],
                      @[ NSLocalizedString(@"SRF", nil),
                         NSLocalizedString(@"RTS", nil),
                         NSLocalizedString(@"RSI", nil),
                         NSLocalizedString(@"RTR", nil),
                         NSLocalizedString(@"SWI", nil) ],
                      @[ NSLocalizedString(@"SRF 1", nil),
                         NSLocalizedString(@"SRF 2 Kultur", nil),
                         NSLocalizedString(@"SRF 3", nil),
                         NSLocalizedString(@"SRF 4 News", nil),
                         NSLocalizedString(@"SRF Musikwelle", nil),
                         NSLocalizedString(@"SRF Virus", nil),
                         NSLocalizedString(@"RTS La 1ère", nil),
                         NSLocalizedString(@"RTS Espace 2", nil),
                         NSLocalizedString(@"RTS Couleur 3", nil),
                         NSLocalizedString(@"RTS Option Musique", nil),
                         NSLocalizedString(@"RTS Podcasts originaux", nil),
                         NSLocalizedString(@"RSI Rete Uno", nil),
                         NSLocalizedString(@"RSI Rete Due", nil),
                         NSLocalizedString(@"RSI Rete Tre", nil),
                         NSLocalizedString(@"RTR", nil) ]];
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
                s_topics = @[ @(TopicListMMF),
                              @(TopicListSRF),
                              @(TopicListRTS),
                              @(TopicListRSI),
                              @(TopicListRTR),
                              @(TopicListSWI) ];
            });
            [self openTopicListWithType:s_topics[indexPath.row].integerValue];
            break;
        }
            
        case 1: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLiveTVSRF),
                             @(MediaListLiveTVRTS),
                             @(MediaListLiveTVRSI),
                             @(MediaListLiveTVRTR) ];
            });
            [self openMediaListWithType:s_lists[indexPath.row].integerValue];
            break;
        }
            
        case 2: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLiveRadioSRF),
                             @(MediaListLiveRadioRTS),
                             @(MediaListLiveRadioRSI),
                             @(MediaListLiveRadioRTR) ];
            });
            [self openMediaListWithType:s_lists[indexPath.row].integerValue];
            break;
        }
            
        case 3: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLiveCenterSRF),
                             @(MediaListLiveCenterAllSRF),
                             @(MediaListLiveCenterRTS),
                             @(MediaListLiveCenterAllRTS),
                             @(MediaListLiveCenterRSI),
                             @(MediaListLiveCenterAllRSI) ];
            });
            [self openMediaListWithType:s_lists[indexPath.row].integerValue];
            break;
        }
            
        case 4: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLiveWebSRF),
                             @(MediaListLiveWebRTS),
                             @(MediaListLiveWebRSI),
                             @(MediaListLiveWebRTR) ];
            });
            [self openMediaListWithType:s_lists[indexPath.row].integerValue];
            break;
        }
            
        case 5: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLatestVideosSRF),
                             @(MediaListLatestVideosRTS),
                             @(MediaListLatestVideosRSI),
                             @(MediaListLatestVideosRTR),
                             @(MediaListLatestVideosSWI) ];
            });
            [self openMediaListWithType:s_lists[indexPath.row].integerValue];
            break;
        }
            
        case 6: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSNumber *> *s_lists;
            dispatch_once(&s_onceToken, ^{
                s_lists = @[ @(MediaListLatestAudiosSRF1),
                             @(MediaListLatestAudiosSRF2),
                             @(MediaListLatestAudiosSRF3),
                             @(MediaListLatestAudiosSRF4),
                             @(MediaListLatestAudiosSRF5),
                             @(MediaListLatestAudiosSRF6),
                             @(MediaListLatestAudiosRTS1),
                             @(MediaListLatestAudiosRTS2),
                             @(MediaListLatestAudiosRTS3),
                             @(MediaListLatestAudiosRTS4),
                             @(MediaListLatestAudiosRTS5),
                             @(MediaListLatestAudiosRSI1),
                             @(MediaListLatestAudiosRSI2),
                             @(MediaListLatestAudiosRSI3),
                             @(MediaListLatestAudiosRTR) ];
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
