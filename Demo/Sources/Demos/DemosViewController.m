//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "AutoplayViewController.h"
#import "MediaListViewController.h"
#import "ModalPlayerViewController.h"
#import "MultiPlayerViewController.h"
#import "NSBundle+LetterboxDemo.h"
#import "PlaylistViewController.h"
#import "SettingsViewController.h"
#import "SimplePlayerViewController.h"
#import "StandalonePlayerViewController.h"
#import "TopicListViewController.h"

#import <libextobjc/libextobjc.h>

@interface DemosViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsBarButtonItem;

@property (nonatomic) SRGDataProvider *dataProvider;

@end

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
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
    NSString *bundleNameSuffix = [[NSBundle mainBundle].infoDictionary objectForKey:@"BundleNameSuffix"];
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
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN serviceURL:serviceURL updateInterval:updateInterval];
    
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
    [[self.dataProvider latestEpisodesForShowWithURN:URN maximumPublicationMonth:nil completionBlock:^(SRGEpisodeComposition * _Nullable episodeComposition, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
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
        
        [self openPlaylistWithMedias:[medias copy]];
    }] resume];
}

- (void)openPlaylistWithMedias:(NSArray<SRGMedia *> *)medias
{
    PlaylistViewController *playlistViewController = [[PlaylistViewController alloc] initWithMedias:medias];
    
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
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    [self presentViewController:playerViewController animated:YES completion:nil];
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

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kVideoOnDemandURNString = @"urn:swi:video:41981254";
    static NSString * const kVideoOnDemandShortClipURNString = @"urn:rts:video:8591082";
    static NSString * const kVideoOnDemandSegmentsURNString = @"urn:rts:video:8992584";
    static NSString * const kVideoOnDemandStartOnSegmentURNString = @"urn:rts:video:8992594";
    static NSString * const kVideoOnDemandWithNoFullLengthURNString = @"urn:rts:video:8686071";
    static NSString * const kVideoOnDemandBlockedSegmentURNString = @"urn:srf:video:84135f7b-c58d-4a2d-b0b0-e8680581eede";
    static NSString * const kVideoOnDemandBlockedSegmentOverlapURNString = @"urn:srf:video:d57f5c1c-080f-49a2-864e-4a1a83e41ae1";
    static NSString * const kVideoOnDemandHybridURNString = @"urn:rts:audio:8581974";
    static NSString * const kVideoOnDemand360URNString = @"urn:rts:video:8414077";
    static NSString * const kVideoOnDemandWithChapters360URNString = @"urn:rts:video:7800215";
    static NSString * const kVideoOnDemandNoTokenURNString = @"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25";
    
    static NSString * const kVideoDVRURNString = @"urn:rts:video:1967124";
    static NSString * const kVideoLiveURNString = @"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0";
    
    static NSString * const kMMFScheduledLivestreamURNString = @"urn:rts:video:_rts_info_delay";
    static NSString * const kMMFCachedScheduledLivestreamURNString = @"urn:rts:video:_rts_info_cacheddelay";
    static NSString * const kMMFTemporarilyGeoblockedURNString = @"urn:rts:video:_rts_info_geoblocked";
    static NSString * const kMMFDVRKillSwitchURNString = @"urn:rts:video:_rts_info_killswitch";
    static NSString * const kMMFSwissTxtFullDVRStreamURNString = @"urn:rts:video:_rts_info_fulldvr";
    static NSString * const kMMFSwissTxtLimitedDVRStreamURNString = @"urn:rts:video:_rts_info_liveonly_limiteddvr";
    static NSString * const kMMFSwissTxtLiveOnlyStreamURNString = @"urn:rts:video:_rts_info_liveonly_delay";
    static NSString * const kMMFSwissTxtFullDVRStartDateChangeStreamURNString = @"urn:rts:video:_rts_info_fulldvrstartdate";
    static NSString * const kMMFTemporarilyNotFoundURNString = @"urn:rts:video:_rts_info_notfound";
    static NSString * const kMMFRTSMultipleAudiosURNString = @"urn:rts:video:_rtsvo_multipleaudios_staging";
    
    static NSString * const kVideoOverriddenURNString = @"urn:rts:video:8806790";
    
    static NSString * const kAudioOnDemandURNString = @"urn:srf:audio:0d666ad6-b191-4f45-9762-9a271b52d38a";
    static NSString * const kAudioOnDemandSegmentsURNString = @"urn:rts:audio:9355007";
    static NSString * const kAudioOnDemandStartOnSegmentURNString = @"urn:rts:audio:9355011";
    static NSString * const kAudioDVRURNString = @"urn:rts:audio:3262363";
    static NSString * const kAudioDVRRegionalURNString = @"urn:srf:audio:5e266ba0-f769-4d6d-bd41-e01f188dd106";
    
    static NSString * const kInvalidURNString = @"urn:swi:video:1234567";
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    [self openSimplePlayerWithURN:kVideoOnDemandURNString];
                    break;
                }
                    
                case 1: {
                    [self openSimplePlayerWithURN:kVideoOnDemandSegmentsURNString];
                    break;
                }
                    
                case 2: {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                        [self openSimplePlayerWithURN:URNString];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self openStandalonePlayerWithURN:kVideoOnDemandURNString];
                    break;
                }
                    
                case 1: {
                    [self openStandalonePlayerWithURN:kVideoOnDemandSegmentsURNString];
                    break;
                }
                    
                case 2: {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                        [self openStandalonePlayerWithURN:URNString];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    [self openModalPlayerWithURN:kVideoOnDemandURNString];
                    break;
                }
                    
                case 1: {
                    [self openModalPlayerWithURN:kVideoOnDemandShortClipURNString];
                    break;
                }
                    
                case 2: {
                    [self openModalPlayerWithURN:kVideoOnDemandSegmentsURNString];
                    break;
                }
                    
                case 3: {
                    [self openModalPlayerWithURN:kVideoOnDemandStartOnSegmentURNString];
                    break;
                }
                    
                case 4: {
                    [self openModalPlayerWithURN:kVideoOnDemandWithNoFullLengthURNString];
                    break;
                }
                    
                case 5: {
                    [self openModalPlayerWithURN:kVideoOnDemandBlockedSegmentURNString];
                    break;
                }
                    
                case 6: {
                    [self openModalPlayerWithURN:kVideoOnDemandBlockedSegmentOverlapURNString];
                    break;
                }
                    
                case 7: {
                    [self openModalPlayerWithURN:kVideoOnDemandHybridURNString];
                    break;
                }
                    
                case 8: {
                    [self openModalPlayerWithURN:kVideoOnDemand360URNString];
                    break;
                }
                    
                case 9: {
                    [self openModalPlayerWithURN:kVideoOnDemandWithChapters360URNString];
                    break;
                }
                    
                case 10: {
                    [self openModalPlayerWithURN:kVideoOnDemandNoTokenURNString];
                    break;
                }
                    
                case 11: {
                    [self openModalPlayerWithURN:kVideoDVRURNString];
                    break;
                }
                    
                case 12: {
                    [self openModalPlayerWithURN:kVideoLiveURNString];
                    break;
                }
                    
                case 13: {
                    [self openModalPlayerWithURN:kAudioOnDemandURNString];
                    break;
                }
                    
                case 14: {
                    [self openModalPlayerWithURN:kAudioOnDemandSegmentsURNString];
                    break;
                }
                    
                case 15: {
                    [self openModalPlayerWithURN:kAudioOnDemandStartOnSegmentURNString];
                    break;
                }
                    
                case 16: {
                    [self openModalPlayerWithURN:kAudioDVRURNString];
                    break;
                }
                    
                case 17: {
                    [self openModalPlayerWithURN:kAudioDVRRegionalURNString];
                    break;
                }
                    
                case 18: {
                    [self openModalPlayerWithURN:kInvalidURNString];
                    break;
                }
                    
                case 19: {
                    [self openModalPlayerWithURN:nil];
                    break;
                }
                    
                case 20: {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                        [self openModalPlayerWithURN:URNString];
                    }];
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
                    [self openModalPlayerWithURN:kVideoOverriddenURNString];
                    break;
                }
                    
                case 1: {
                    [self openModalPlayerWithURN:kMMFScheduledLivestreamURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 2: {
                    NSDate *nowDate = NSDate.date;
                    
                    NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
                    startDateComponents.day = 100;
                    startDateComponents.second = 7;
                    NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
                    
                    NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
                    endDateComponents.day = 101;
                    NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
                    
                    NSString *URNString = [NSString stringWithFormat:@"%@_%@_%@", kMMFScheduledLivestreamURNString, @(startTimestamp), @(endTimestamp)];
                    [self openModalPlayerWithURN:URNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 3: {
                    NSDate *nowDate = NSDate.date;
                    
                    NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
                    startDateComponents.day = 1;
                    startDateComponents.second = 7;
                    NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
                    
                    NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
                    endDateComponents.day = 2;
                    NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
                    
                    NSString *URNString = [NSString stringWithFormat:@"%@_%@_%@", kMMFScheduledLivestreamURNString, @(startTimestamp), @(endTimestamp)];
                    [self openModalPlayerWithURN:URNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 4: {
                    NSDate *nowDate = NSDate.date;
                    
                    NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
                    startDateComponents.hour = 1;
                    startDateComponents.second = 7;
                    NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
                    
                    NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
                    endDateComponents.hour = 2;
                    NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
                    
                    NSString *URNString = [NSString stringWithFormat:@"%@_%@_%@", kMMFScheduledLivestreamURNString, @(startTimestamp), @(endTimestamp)];
                    [self openModalPlayerWithURN:URNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 5: {
                    [self openModalPlayerWithURN:kMMFCachedScheduledLivestreamURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 6: {
                    [self openModalPlayerWithURN:kMMFTemporarilyGeoblockedURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 7: {
                    [self openModalPlayerWithURN:kMMFDVRKillSwitchURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 8: {
                    [self openModalPlayerWithURN:kMMFSwissTxtFullDVRStreamURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 9: {
                    [self openModalPlayerWithURN:kMMFSwissTxtLimitedDVRStreamURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 10: {
                    [self openModalPlayerWithURN:kMMFSwissTxtLiveOnlyStreamURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 11: {
                    [self openModalPlayerWithURN:kMMFSwissTxtFullDVRStartDateChangeStreamURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 12: {
                    [self openModalPlayerWithURN:kMMFTemporarilyNotFoundURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(LetterboxDemoSettingUpdateIntervalShort)];
                    break;
                }
                    
                case 13: {
                    [self openModalPlayerWithURN:kMMFRTSMultipleAudiosURNString
                                      serviceURL:LetterboxDemoMMFServiceURL()
                                  updateInterval:@(SRGLetterboxDefaultUpdateInterval)];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 4: {
            switch (indexPath.row) {
                case 0: {
                    [self openMultiPlayerWithURN:@"urn:rts:video:3608506" URN1:@"urn:rts:video:3608517" URN2:kVideoDVRURNString];
                    break;
                }
                    
                case 1: {
                    [self openMultiPlayerWithURN:kVideoOnDemand360URNString URN1:kVideoOnDemandSegmentsURNString URN2:kVideoDVRURNString];
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
            AutoplayList autoplayList = AutoplayListUnknown;
            switch (indexPath.row) {
                case 0: {
                    autoplayList = AutoplayListSRFTrendingMedias;
                    break;
                }
                    
                case 1: {
                    autoplayList = AutoplayListRTSTrendingMedias;
                    break;
                }
                    
                case 2: {
                    autoplayList = AutoplayListRSITrendingMedias;
                    break;
                }
                    
                default: {
                    break;
                }
            }
            
            AutoplayViewController *autoplayViewController = [[AutoplayViewController alloc] init];
            autoplayViewController.autoplayList = autoplayList;
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
