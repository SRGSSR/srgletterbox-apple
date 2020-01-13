//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MiscellaneousViewController.h"

#import "FeedsViewController.h"
#import "MultiPlayerViewController.h"
#import "PageViewController.h"
#import "SettingsViewController.h"
#import "SimplePlayerViewController.h"
#import "StandalonePlayerViewController.h"
#import "PlaylistViewController.h"

#import <libextobjc/libextobjc.h>

@interface MiscellaneousViewController ()

@property (nonatomic) SRGDataProvider *dataProvider;

@end

@implementation MiscellaneousViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Miscellaneous", nil);
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

- (void)openPlaylistForShowWithURN:(NSString *)URN
{
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

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ NSLocalizedString(@"Simple player", nil),
                      NSLocalizedString(@"Standalone player", nil),
                      NSLocalizedString(@"Multiple player", nil),
                      NSLocalizedString(@"Feeds", nil),
                      NSLocalizedString(@"Playlists", nil),
                      NSLocalizedString(@"Page navigation", nil) ];
    });
    return s_titles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        s_rows = @[ @3,
                    @3,
                    @4,
                    @3,
                    @3,
                    @1 ];
    });
    return s_rows[section].integerValue;
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
    static dispatch_once_t s_onceToken;
    static NSArray<NSArray<NSString *> *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @[ @[ NSLocalizedString(@"SWI VOD", nil),
                         NSLocalizedString(@"RTS VOD (segments)", nil),
                         NSLocalizedString(@"SRF AOD", nil) ],
                      @[ NSLocalizedString(@"SWI VOD", nil),
                         NSLocalizedString(@"RTS VOD (segments)", nil),
                         NSLocalizedString(@"SRF AOD", nil) ],
                      @[ NSLocalizedString(@"RTS livestreams", nil),
                         NSLocalizedString(@"Various streams", nil),
                         NSLocalizedString(@"Non-protected streams", nil),
                         NSLocalizedString(@"Various streams with errors", nil)],
                      @[ NSLocalizedString(@"Most popular SRF videos", nil),
                         NSLocalizedString(@"Most popular RTS videos", nil),
                         NSLocalizedString(@"Most popular RSI videos", nil)],
                      @[ NSLocalizedString(@"Le Court du Jour", nil),
                         NSLocalizedString(@"19h30", nil),
                         NSLocalizedString(@"Sexomax", nil)],
                      @[ NSLocalizedString(@"Various medias", nil) ] ];
    });
    cell.textLabel.text = s_titles[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_URNs;
            dispatch_once(&s_onceToken, ^{
                s_URNs = @[ @"urn:swi:video:41981254",
                            @"urn:rts:video:10623665",
                            @"urn:srf:audio:0d666ad6-b191-4f45-9762-9a271b52d38a" ];
            });
            [self openSimplePlayerWithURN:s_URNs[indexPath.row]];
            break;
        }
            
        case 1: {
            static dispatch_once_t s_onceToken;
            static NSArray<NSString *> *s_URNs;
            dispatch_once(&s_onceToken, ^{
                s_URNs = @[ @"urn:swi:video:41981254",
                            @"urn:rts:video:10623665",
                            @"urn:srf:audio:0d666ad6-b191-4f45-9762-9a271b52d38a" ];
            });
            [self openStandalonePlayerWithURN:s_URNs[indexPath.row]];
            break;
        }
        
        case 2: {
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
        
        case 3: {
            FeedsViewController *feedsViewController = [[FeedsViewController alloc] init];
            switch (indexPath.row) {
                case 0: {
                    feedsViewController.feed = FeedSRFTrendingMedias;
                    break;
                }
                    
                case 1: {
                    feedsViewController.feed = FeedRTSTrendingMedias;
                    break;
                }
                    
                case 2: {
                    feedsViewController.feed = FeedRSITrendingMedias;
                    break;
                }
                    
                default: {
                    feedsViewController.feed = FeedRTSTrendingMedias;
                    break;
                }
            }
            [self.navigationController pushViewController:feedsViewController animated:YES];
            break;
        }
        
        case 4: {
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
            
        case 5: {
            [self openPlayerPagesWithURNs:@[ @"urn:swi:video:41981254",
                                             @"urn:rts:video:8591082",
                                             @"urn:rts:video:8686071",
                                             @"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25",
                                             @"urn:rts:video:1967124",
                                             @"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0",
                                             @"urn:srf:audio:0d666ad6-b191-4f45-9762-9a271b52d38a",
                                             @"urn:rts:audio:3262363" ]];
            break;
        }
            
        default: {
            break;
        }
    }
}

@end
