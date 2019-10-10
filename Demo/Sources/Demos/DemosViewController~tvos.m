//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "DemoSection.h"
#import "Media.h"
#import "MediaListViewController.h"
#import "Playlist.h"
#import "SettingsViewController.h"
#import "TopicListViewController.h"
#import "UIViewController+LetterboxDemo.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface DemosViewController () <SRGLetterboxViewControllerDelegate>

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) Playlist *playlist;

@property (nonatomic) NSArray<Media *> *medias;
@property (nonatomic) NSArray<Media *> *specialMedias;

@end

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Demos", nil);
}

#pragma mark Media extraction

- (NSArray<Media *> *)medias
{
    if (! _medias) {
        NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"MediaDemoConfiguration" ofType:@"plist"];
        _medias = [Media mediasFromFileAtPath:filePath];
    }
    return _medias;
}

- (NSArray<Media *> *)specialMedias
{
    if (! _specialMedias) {
        NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"SpecialMediaDemoConfiguration" ofType:@"plist"];
        _specialMedias = [Media mediasFromFileAtPath:filePath];
    }
    return _specialMedias;
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return DemoSection.homeSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return DemoSection.homeSections[section].headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return DemoSection.homeSections[section].footerTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // TODO: Dark mode compatibility. Cell backgrounds? (also update other SRG SSR library demos)
    NSInteger count = 0;
    switch (section) {
        case 0: {
            count = self.medias.count;
            break;
        }
            
        case 1: {
            count = self.specialMedias.count;
            break;
        }
            
        case 2: {
            count = 3;
            break;
        }
            
        case 3: {
            count = 6;
            break;
        }
            
        default:
            break;
    }
    return count;
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

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = nil;

    switch (indexPath.section) {
        case 0: {
            name = self.medias[indexPath.row].name;
            break;
        }
            
        case 1: {
            name = self.specialMedias[indexPath.row].name;
            break;
        }
        
        case 2: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_mediaLists;
            dispatch_once(&s_onceToken, ^{
                s_mediaLists = @[ NSLocalizedString(@"SRF live center", nil),
                                  NSLocalizedString(@"RTS live center", nil),
                                  NSLocalizedString(@"RSI live center", nil)];
            });
            
            name = s_mediaLists[indexPath.row];
            break;
        }
            
        case 3: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_topicLists;
            dispatch_once(&s_onceToken, ^{
                s_topicLists = @[ NSLocalizedString(@"SRF topics", nil),
                                  NSLocalizedString(@"RTS topics", nil),
                                  NSLocalizedString(@"RSI topics", nil),
                                  NSLocalizedString(@"RTR topics", nil),
                                  NSLocalizedString(@"SWI topics", nil),
                                  NSLocalizedString(@"Play MMF topics", nil)];
            });
            
            name = s_topicLists[indexPath.row];
            break;
        }
            
        default:
            break;
    }
    cell.textLabel.text = name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            [self openPlayerWithURN:self.medias[indexPath.row].URN];
            break;
        }
            
        case 1: {
            Media *media = self.specialMedias[indexPath.row];
            if (media.onMMF) {
                [self openPlayerWithURN:media.URN
                             serviceURL:LetterboxDemoMMFServiceURL()
                         updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
            }
            else {
                [self openPlayerWithURN:media.URN];
            }
            break;
        }
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    [self openMediaListWithType:MediaListLivecenterSRF];
                    break;
                }
                    
                case 1: {
                    [self openMediaListWithType:MediaListLivecenterRTS];
                    break;
                }
                    
                case 2: {
                    [self openMediaListWithType:MediaListLivecenterRSI];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    [self openTopicListWithType:TopicListSRF];
                    break;
                }
                    
                case 1: {
                    [self openTopicListWithType:TopicListRTS];
                    break;
                }
                    
                case 2: {
                    [self openTopicListWithType:TopicListRSI];
                    break;
                }
                    
                case 3: {
                    [self openTopicListWithType:TopicListRTR];
                    break;
                }
                    
                case 4: {
                    [self openTopicListWithType:TopicListSWI];
                    break;
                }
                    
                case 5: {
                    [self openTopicListWithType:TopicListMMF];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma Actions

- (void)openMediaListWithType:(MediaList)MediaList
{
    MediaListViewController *mediaListViewController = [[MediaListViewController alloc] initWithMediaList:MediaList topic:nil MMFOverride:NO];
    [self.navigationController pushViewController:mediaListViewController animated:YES];
}

- (void)openTopicListWithType:(TopicList)TopicList
{
    TopicListViewController *topicListViewController = [[TopicListViewController alloc] initWithTopicList:TopicList];
    [self.navigationController pushViewController:topicListViewController animated:YES];
}

@end
