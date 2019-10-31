//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "DemoSection.h"
#import "Media.h"
#import "MediaListViewController.h"
#import "NSBundle+LetterboxDemo.h"
#import "Playlist.h"
#import "SettingsViewController.h"
#import "TopicListViewController.h"
#import "UIViewController+LetterboxDemo.h"

#import <SRGLetterbox/SRGLetterbox.h>

#if TARGET_OS_IOS
#import "AutoplayViewController.h"
#import "ModalPlayerViewController.h"
#import "MultiPlayerViewController.h"
#import "PageViewController.h"
#import "PlaylistViewController.h"
#import "SimplePlayerViewController.h"
#import "StandalonePlayerViewController.h"

#import <libextobjc/libextobjc.h>

@interface DemosViewController () <UIPopoverPresentationControllerDelegate>
#else
@interface DemosViewController ()
#endif

@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsBarButtonItem;

@property (nonatomic) SRGDataProvider *dataProvider;

@property (nonatomic) NSArray<Media *> *medias;
@property (nonatomic) NSArray<Media *> *specialMedias;

@end

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [self pageTitle];
    
    UIBarButtonItem * settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(showSettings:)];
    settingsBarButtonItem.accessibilityLabel = NSLocalizedString(@"Settings", @"Settings button label on main view");
    self.navigationItem.rightBarButtonItem = self.settingsBarButtonItem = settingsBarButtonItem;
}

#pragma mark Getters and setters

- (NSString *)pageTitle
{
    NSString *bundleNameSuffix = [NSBundle.mainBundle.infoDictionary objectForKey:@"BundleNameSuffix"];
    return [NSString stringWithFormat:@"Letterbox %@%@", SRGLetterboxMarketingVersion(), bundleNameSuffix];
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
    DemoSectionId sectionId = DemoSection.homeSections[section].sectionId;
    NSInteger count = 0;
    switch (sectionId) {
#if TARGET_OS_IOS
        case DemoSectionIdBasicPlayer:
        case DemoSectionIdStandalonePlayer: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, basic), @(YES)];
            count = [self.medias filteredArrayUsingPredicate:predicate].count;
            break;
        }
            
        case DemoSectionIdMultiplePlayer: {
            count = 4;
            break;
        }
            
        case DemoSectionIdAutoplay:
        case DemoSectionIdPlaylists: {
            count = 3;
            break;
        }
            
        case DemoSectionIdPagenavigation: {
            count = 1;
            break;
        }
#endif
        case DemoSectionIdSRGSSRContent: {
            count = self.medias.count + 1;
            break;
        }
            
        case DemoSectionIdSpecialCases: {
            count = self.specialMedias.count;
            break;
        }
            
        case DemoSectionIdMediaLists: {
            count = 3;
            break;
        }
            
        case DemoSectionIdTopicLists: {
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
    DemoSectionId sectionId = DemoSection.homeSections[indexPath.section].sectionId;
    NSString *name = nil;
    switch (sectionId) {
#if TARGET_OS_IOS
        case DemoSectionIdBasicPlayer:
        case DemoSectionIdStandalonePlayer: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, basic), @(YES)];
            name = [self.medias filteredArrayUsingPredicate:predicate][indexPath.row].name;
            break;
        }
            
        case DemoSectionIdMultiplePlayer: {
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
            
        case DemoSectionIdAutoplay: {
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
        
        case DemoSectionIdPlaylists: {
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
            
        case DemoSectionIdPagenavigation: {
            name = NSLocalizedString(@"Various medias", nil);
            break;
        }
#endif
        case DemoSectionIdSRGSSRContent: {
            if (indexPath.row < self.medias.count) {
                name = self.medias[indexPath.row].name;
            }
            else {
                name = NSLocalizedString(@"Other media", nil);
            }
            break;
        }
            
        case DemoSectionIdSpecialCases: {
            name = self.specialMedias[indexPath.row].name;
            break;
        }
            
        case DemoSectionIdMediaLists: {
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
            
        case DemoSectionIdTopicLists: {
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

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DemoSectionId sectionId = DemoSection.homeSections[indexPath.section].sectionId;
    switch (sectionId) {
#if TARGET_OS_IOS
        case DemoSectionIdBasicPlayer:
        case DemoSectionIdStandalonePlayer: {
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
            
        case DemoSectionIdMultiplePlayer: {
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
            
        case DemoSectionIdAutoplay: {
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
            
        case DemoSectionIdPlaylists: {
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
            
        case DemoSectionIdPagenavigation: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(Media.new, pageNagivation), @(YES)];
            NSArray<Media *> *medias = [self.medias filteredArrayUsingPredicate:predicate];
            [self openPlayerPagesWithURNs: [medias valueForKey:@keypath(Media.new, URN)]];
            break;
        }
#endif
        case DemoSectionIdSRGSSRContent: {
            if (indexPath.row < self.medias.count) {
                NSString *URN = self.medias[indexPath.row].URN;
                [self openPlayerWithURN:URN];
            }
            else {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                    [self openPlayerWithURN:URNString];
                }];
            }
            break;
        }
            
        case DemoSectionIdSpecialCases: {
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
            
        case DemoSectionIdMediaLists: {
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
            
        case DemoSectionIdTopicLists: {
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

- (IBAction)showSettings:(id)sender
{
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
#if TARGET_OS_IOS
    settingsViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    settingsViewController.popoverPresentationController.delegate = self;
    settingsViewController.popoverPresentationController.barButtonItem = self.settingsBarButtonItem;
    
    [self presentViewController:settingsViewController animated:YES completion:nil];
#else
    [self.navigationController pushViewController:settingsViewController animated:YES];
#endif
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

#if TARGET_OS_IOS
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
        
        [self openPlaylistWithMedias:medias.copy sourceUid:sourceUid];
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
#endif

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

@end
