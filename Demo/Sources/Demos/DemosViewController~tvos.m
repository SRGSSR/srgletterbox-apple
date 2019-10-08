//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "Media.h"
#import "Playlist.h"

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
    return 2;
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

#pragma mark SRGLetterboxViewControllerDelegate protocol

- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
            
        default:
            break;
    }
    cell.textLabel.text = name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Media *media = nil;
    switch (indexPath.section) {
        case 0: {
            media = self.medias[indexPath.row];
            break;
        }
            
        case 1: {
            media = self.specialMedias[indexPath.row];
            break;
        }
            
        default:
            break;
    }
    
    SRGLetterboxViewController *letterboxViewController = [[SRGLetterboxViewController alloc] init];
    letterboxViewController.delegate = self;
    letterboxViewController.controller.contentURLOverridingBlock = ^(NSString * _Nonnull URN) {
        return [URN isEqualToString:@"urn:rts:video:8806790"] ? [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"] : nil;
    };
    if (media.onMMF) {
        letterboxViewController.controller.serviceURL = [NSURL URLWithString:@"https://play-mmf.herokuapp.com/integrationlayer"];
        letterboxViewController.controller.updateInterval = 10.;
    }
    
    if (media.URN) {
        [letterboxViewController.controller playURN:media.URN atPosition:nil withPreferredSettings:nil];
        
        self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
        [[self.dataProvider recommendedMediasForURN:media.URN userId:nil withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            self.playlist = [[Playlist alloc] initWithMedias:medias sourceUid:nil];
            self.playlist.continuousPlaybackTransitionDuration = 30.;
            letterboxViewController.controller.playlistDataSource = self.playlist;
        }] resume];
    }
    [self presentViewController:letterboxViewController animated:YES completion:nil];
}

// TODO: Not for tvOS
- (void)openModalPlayerWithURN:(NSString *)URN serviceURL:(NSURL *)serviceURL updateInterval:(NSNumber *)updateInterval
{}

@end
