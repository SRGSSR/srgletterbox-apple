//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "Playlist.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface DemosViewController ()

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) Playlist *playlist;

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

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 19;
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
    // TODO: Should factor out (at least part of) iOS and tvOS demos
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @0 : NSLocalizedString(@"SWI VOD", nil),
                      @1 : NSLocalizedString(@"RTS VOD (short clip)", nil),
                      @2 : NSLocalizedString(@"RTS VOD (segments)", nil),
                      @3 : NSLocalizedString(@"RTS VOD (start on segment)", nil),
                      @4 : NSLocalizedString(@"RTS VODs with no full-length", nil),
                      @5 : NSLocalizedString(@"SRF VOD (blocked segment at 29:26)", nil),
                      @6 : NSLocalizedString(@"SRF VOD (blocked overlap)", nil),
                      @7 : NSLocalizedString(@"Hybrid VOD (audio / video)", nil),
                      @8 : NSLocalizedString(@"RTS Le Gotthard 360 VOD", nil),
                      @9 : NSLocalizedString(@"RTS Le Goût du risque 360 VOD", nil),
                      @10 : NSLocalizedString(@"SRF VOD (no token protection)", nil),
                      @11 : NSLocalizedString(@"RTS Info DVR", nil),
                      @12 : NSLocalizedString(@"SRF Info LIVE", nil),
                      @13 : NSLocalizedString(@"SRF AOD", nil),
                      @14 : NSLocalizedString(@"RTS AOD (segments)", nil),
                      @15 : NSLocalizedString(@"RTS AOD (start on segment)", nil),
                      @16 : NSLocalizedString(@"Couleur 3 DVR", nil),
                      @17 : NSLocalizedString(@"SRF 1 (Region Zurich) DVR", nil),
                      @18 : NSLocalizedString(@"Invalid media", nil)
        };
    });
    cell.textLabel.text = s_titles[@(indexPath.row)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Should factor out (at least part of) iOS and tvOS demos
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_URNs;
    dispatch_once(&s_onceToken, ^{
        s_URNs = @{ @0 : @"urn:swi:video:41981254",
                    @1 : @"urn:rts:video:8591082",
                    @2 : @"urn:rts:video:10623665",
                    @3 : @"urn:rts:video:10623653",
                    @4 : @"urn:rts:video:8686071",
                    @5 : @"urn:srf:video:84135f7b-c58d-4a2d-b0b0-e8680581eede",
                    @6 : @"urn:srf:video:d57f5c1c-080f-49a2-864e-4a1a83e41ae1",
                    @7 : @"urn:rts:audio:8581974",
                    @8 : @"urn:rts:video:8414077",
                    @9 : @"urn:rts:video:7800215",
                    @10 : @"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25",
                    @11 : @"urn:rts:video:1967124",
                    @12 : @"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0",
                    @13 : @"urn:srf:audio:0d666ad6-b191-4f45-9762-9a271b52d38a",
                    @14 : @"urn:rts:audio:9355007",
                    @15 : @"urn:rts:audio:9355011",
                    @16 : @"urn:rts:audio:3262363",
                    @17 : @"urn:srf:audio:5e266ba0-f769-4d6d-bd41-e01f188dd106",
                    @18 : @"urn:swi:video:1234567"
        };
    });
    
    NSString *URN = s_URNs[@(indexPath.row)];
    SRGLetterboxViewController *letterboxViewController = [[SRGLetterboxViewController alloc] init];
    [letterboxViewController.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    [self presentViewController:letterboxViewController animated:YES completion:nil];
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    [[self.dataProvider recommendedMediasForURN:URN userId:nil withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias sourceUid:nil];
        self.playlist.continuousPlaybackTransitionDuration = 5.;
        letterboxViewController.controller.playlistDataSource = self.playlist;
    }] resume];
}

// TODO: Not for tvOS
- (void)openModalPlayerWithURN:(NSString *)URN serviceURL:(NSURL *)serviceURL updateInterval:(NSNumber *)updateInterval
{}

@end
