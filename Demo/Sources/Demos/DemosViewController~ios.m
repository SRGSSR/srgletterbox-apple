//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "AutoplayViewController.h"
#import "Media.h"
#import "MediaListViewController.h"
#import "ModalPlayerViewController.h"
#import "MultiPlayerViewController.h"
#import "NSBundle+LetterboxDemo.h"
#import "PageViewController.h"
#import "PlaylistViewController.h"
#import "SettingsViewController.h"
#import "SimplePlayerViewController.h"
#import "StandalonePlayerViewController.h"
#import "TopicListViewController.h"

#import <libextobjc/libextobjc.h>

@interface DemosViewController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsBarButtonItem;

@property (nonatomic) SRGDataProvider *dataProvider;

@property (nonatomic) NSArray<Media *> *medias;
@property (nonatomic) NSArray<Media *> *specialMedias;

@end

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LetterboxDemoResourceNameForUIClass(self.class) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [self pageTitle];
    
    self.settingsBarButtonItem.accessibilityLabel = NSLocalizedString(@"Settings", @"Settings button label on main view");
}

#pragma mark Getters and setters

- (NSString *)pageTitle
{
    NSString *bundleNameSuffix = [NSBundle.mainBundle.infoDictionary objectForKey:@"BundleNameSuffix"];
    return [NSString stringWithFormat:@"Letterbox %@%@", SRGLetterboxMarketingVersion(), bundleNameSuffix];
}

#pragma mark Players

- (void)openSimplePlayerWithURN:(NSString *)URN
{
    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
    [self.navigationController pushViewController:playerViewController animated:YES];
}

- (void)openStandalonePlayerWithURN:(NSString *)URN
{
    StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)openModalPlayerWithURN:(NSString *)URN
{
    [self openModalPlayerWithURN:URN serviceURL:nil updateInterval:nil];
}

- (void)openModalPlayerWithURN:(NSString *)URN serviceURL:(NSURL *)serviceURL updateInterval:(NSNumber *)updateInterval
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN serviceURL:serviceURL updateInterval:updateInterval];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    
    [self presentViewController:playerViewController animated:YES completion:nil];
}

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

- (void)openPlaylistForShowWithURN:(NSString *)URN
{
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ApplicationSettingServiceURL()];
    [[self.dataProvider latestEpisodesForShowWithURN:URN maximumPublicationDay:nil completionBlock:^(SRGEpisodeComposition * _Nullable episodeComposition, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGMedia.new, contentType), @(SRGContentTypeEpisode)];
        
        NSMutableArray *medias = [NSMutableArray array];
        for (SRGEpisode *episode in episodeComposition.episodes) {
            NSArray *mediasForEpisode = [episode.medias filteredArrayUsingPredicate:predicate];
            [medias addObjectsFromArray:mediasForEpisode];
        }
        
        NSString *domain = [[[[HTTPResponse.URL.host componentsSeparatedByString:@"."] reverseObjectEnumerator] allObjects] componentsJoinedByString:@"."];
        NSString *path = [HTTPResponse.URL.path.stringByDeletingPathExtension substringFromIndex:1];
        NSString *sourceUid = [NSString stringWithFormat:@"%@:%@/%d", domain, path, @(NSDate.date.timeIntervalSince1970).intValue];
        
        [self openPlaylistWithMedias:[medias copy] sourceUid:sourceUid];
    }] resume];
}

- (void)openPlaylistWithMedias:(NSArray<SRGMedia *> *)medias sourceUid:(NSString *)sourceUid
{
    PlaylistViewController *playlistViewController = [[PlaylistViewController alloc] initWithMedias:medias sourceUid:sourceUid];
    playlistViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playlistViewController.presentingViewController) {
        return;
    }
    
    [self presentViewController:playlistViewController animated:YES completion:nil];
}

- (void)openMultiPlayerWithURN:(NSString *)URN URN1:(NSString *)URN1 URN2:(NSString *)URN2
{
    MultiPlayerViewController *playerViewController = [[MultiPlayerViewController alloc] initWithURN:URN URN1:URN1 URN2:URN2 userInterfaceAlwaysHidden:YES];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)openPlayerPagesWithURNs:(NSArray<NSString *> *)URNs
{
    PageViewController *pageViewController = [[PageViewController alloc] initWithURNs:URNs];
    [self.navigationController pushViewController:pageViewController animated:YES];
}

- (void)openCustomURNEntryAlertWithCompletionBlock:(void (^)(NSString * _Nullable URNString))completionBlock
{
    NSParameterAssert(completionBlock);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter media URN", nil)
                                                                             message:NSLocalizedString(@"For example: urn:[BU]:[video|audio]:[uid]", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LetterboxDemoNonLocalizedString(@"urn:swi:video:41981254");
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Play", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completionBlock(alertController.textFields.firstObject.text);
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
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
    return 10;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_sectionHeaders;
    dispatch_once(&s_onceToken, ^{
        s_sectionHeaders = @[ NSLocalizedString(@"Basic player", nil),
                              NSLocalizedString(@"Standalone player", nil),
                              NSLocalizedString(@"Advanced player", nil),
                              NSLocalizedString(@"Advanced player (special cases)", nil),
                              NSLocalizedString(@"Multiple player", nil),
                              NSLocalizedString(@"Autoplay", nil),
                              NSLocalizedString(@"Media lists", nil),
                              NSLocalizedString(@"Topic lists", nil),
                              NSLocalizedString(@"Playlists", nil),
                              NSLocalizedString(@"Page navigation", nil)];
    });
    
    return s_sectionHeaders[section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_sectionFooters;
    dispatch_once(&s_onceToken, ^{
        s_sectionFooters = @[ NSLocalizedString(@"This basic player can be used with AirPlay but does not implement full screen or picture in picture.", nil),
                              NSLocalizedString(@"This player is not enabled for AirPlay playback or picture in picture by default. You can enable or disable these features on the fly.", nil),
                              NSLocalizedString(@"This player implements full screen and picture in picture and can be used with AirPlay. It starts with hidden controls, and a close button has been added as custom control. You can also play with various user interface configurations.", nil),
                              NSLocalizedString(@"Same features as the advanced player, but in special cases.", nil),
                              NSLocalizedString(@"This player plays three streams at the same time, and can be used with AirPlay and picture in picture. You can tap on a smaller stream to play it as main stream.", nil),
                              NSLocalizedString(@"Lists of medias played automatically as they are scrolled.", nil),
                              NSLocalizedString(@"Lists of medias played with the advanced player.", nil),
                              NSLocalizedString(@"Lists of topics, whose medias are played with the advanced player.", nil),
                              NSLocalizedString(@"Medias opened in the context of a playlist.", nil),
                              NSLocalizedString(@"Medias displayed in a page navigation.", nil) ];
    });
    
    return s_sectionFooters[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    switch (section) {
        case 0:
        case 1: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, basic), @(YES)];
            count = [self.medias filteredArrayUsingPredicate:predicate].count;
            break;
        }
            
        case 2: {
            count = self.medias.count + 1;
            break;
        }
            
        case 3: {
            count = self.specialMedias.count;
            break;
        }
            
        case 4: {
            count = 4;
            break;
        }
            
        case 5:
        case 6:
        case 8: {
            count = 3;
            break;
        }
            
        case 7: {
            count = 5;
            break;
        }
            
        case 9: {
            count = 1;
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
        case 0:
        case 1: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, basic), @(YES)];
            name = [self.medias filteredArrayUsingPredicate:predicate][indexPath.row].name;
            break;
        }
            
        case 2: {
            if (indexPath.row < self.medias.count) {
                name = self.medias[indexPath.row].name;
            }
            else {
                name = NSLocalizedString(@"Other media", nil);
            }
            break;
        }
            
        case 3: {
            name = self.specialMedias[indexPath.row].name;
            break;
        }
            
        case 4: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_multiplePlayers;
            dispatch_once(&s_onceToken, ^{
                s_multiplePlayers = @[ NSLocalizedString(@"RTS livestreams", nil),
                                       NSLocalizedString(@"Various streams", nil),
                                       NSLocalizedString(@"Non-protected streams", nil),
                                       NSLocalizedString(@"Various streams with errors", nil)];
            });
            
            name = s_multiplePlayers[indexPath.row];
            break;
        }
            
        case 5: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_autoplays;
            dispatch_once(&s_onceToken, ^{
                s_autoplays = @[ NSLocalizedString(@"Most popular SRF videos", nil),
                                 NSLocalizedString(@"Most popular RTS videos", nil),
                                 NSLocalizedString(@"Most popular RSI videos", nil)];
            });
            
            name = s_autoplays[indexPath.row];
            break;
        }
            
        case 6: {
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
            
        case 7: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_topicLists;
            dispatch_once(&s_onceToken, ^{
                s_topicLists = @[ NSLocalizedString(@"SRF topics", nil),
                                  NSLocalizedString(@"RTS topics", nil),
                                  NSLocalizedString(@"RSI topics", nil),
                                  NSLocalizedString(@"RTR topics", nil),
                                  NSLocalizedString(@"Play MMF topics", nil)];
            });
            
            name = s_topicLists[indexPath.row];
            break;
        }
            
        case 8: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_playlists;
            dispatch_once(&s_onceToken, ^{
                s_playlists = @[ NSLocalizedString(@"Le Court du Jour", nil),
                                 NSLocalizedString(@"19h30", nil),
                                 NSLocalizedString(@"Sexomax", nil)];
            });
            
            name = s_playlists[indexPath.row];
            break;
        }
            
        case 9: {
            name = NSLocalizedString(@"Various medias", nil);
            break;
        }
            
        default:
            break;
    }
    cell.textLabel.text = name;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        case 1: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, basic), @(YES)];
            NSString *URN = [self.medias filteredArrayUsingPredicate:predicate][indexPath.row].URN;
            if (indexPath.section == 0) {
                [self openSimplePlayerWithURN:URN];
            }
            else {
                [self openStandalonePlayerWithURN:URN];
            }
            break;
        }
            
        case 2: {
            if (indexPath.row < self.medias.count) {
                NSString *URN = self.medias[indexPath.row].URN;
                [self openModalPlayerWithURN:URN];
            }
            else {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                    [self openModalPlayerWithURN:URNString];
                }];
            }
            break;
        }
            
        case 3: {
            Media *media = self.specialMedias[indexPath.row];
            if (media.onMMF) {
                [self openModalPlayerWithURN:media.URN
                                  serviceURL:LetterboxDemoMMFServiceURL()
                              updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
            }
            else {
                [self openModalPlayerWithURN:media.URN];
            }
            break;
        }
            
        case 4: {
            switch (indexPath.row) {
                case 0: {
                    [self openMultiPlayerWithURN:@"urn:rts:video:3608506" URN1:@"urn:rts:video:3608517" URN2:@"urn:rts:video:1967124"];
                    break;
                }
                    
                case 1: {
                    [self openMultiPlayerWithURN:@"urn:rts:video:8414077" URN1:@"urn:rts:video:10623665" URN2:@"urn:rts:video:1967124"];
                    break;
                }
                    
                case 2: {
                    [self openMultiPlayerWithURN:@"urn:swi:video:43767184" URN1:@"urn:swi:video:43767258" URN2:@"urn:swi:video:43845942"];
                    break;
                }
                    
                case 3: {
                    [self openMultiPlayerWithURN:@"urn:rts:video:3608517" URN1:nil URN2:@"urn:rts:video:1234567"];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 5: {
            AutoplayViewController *autoplayViewController = [[AutoplayViewController alloc] init];
            switch (indexPath.row) {
                case 0: {
                    autoplayViewController.autoplayList = AutoplayListSRFTrendingMedias;
                    break;
                }
                    
                case 1: {
                    autoplayViewController.autoplayList = AutoplayListRTSTrendingMedias;
                    break;
                }
                    
                case 2: {
                    autoplayViewController.autoplayList = AutoplayListRSITrendingMedias;
                    break;
                }
                    
                default: {
                    autoplayViewController.autoplayList = AutoplayListRTSTrendingMedias;
                    break;
                }
            }
            [self.navigationController pushViewController:autoplayViewController animated:YES];
            break;
        }
            
        case 6: {
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
            
        case 7: {
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
                    [self openTopicListWithType:TopicListMMF];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 8: {
            switch (indexPath.row) {
                case 0: {
                    [self openPlaylistForShowWithURN:@"urn:rts:show:tv:105233"];
                    break;
                }
                    
                case 1: {
                    [self openPlaylistForShowWithURN:@"urn:rts:show:tv:6454706"];
                    break;
                }
                    
                case 2: {
                    [self openPlaylistForShowWithURN:@"urn:rts:show:radio:8864883"];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 9: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, pageNagivation), @(YES)];
            NSArray<Media *> *medias = [self.medias filteredArrayUsingPredicate:predicate];
            [self openPlayerPagesWithURNs: [medias valueForKey:@keypath(Media.new, URN)]];
            break;
        }
            
        default: {
            break;
        }
    }
}

#pragma mark UIPopoverPresentationControllerDelegate protocol

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Needed for the iPhone
    return UIModalPresentationNone;
}

#pragma mark Actions

- (IBAction)showSettingsPopup:(id)sender
{
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    settingsViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    settingsViewController.popoverPresentationController.delegate = self;
    settingsViewController.popoverPresentationController.barButtonItem = self.settingsBarButtonItem;
    
    [self presentViewController:settingsViewController
                       animated:YES
                     completion:nil];
}

@end
