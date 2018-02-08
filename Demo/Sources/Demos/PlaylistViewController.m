//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlaylistViewController.h"

#import "Playlist.h"
#import "SettingsViewController.h"

#import <libextobjc/libextobjc.h>

@interface PlaylistViewController ()

@property (nonatomic, copy) NSString *showURNString;
@property (nonatomic) Playlist *playlist;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained

@property (nonatomic) SRGDataProvider *dataProvider;

@end

@implementation PlaylistViewController

#pragma mark Object lifecycle

- (instancetype)initWithShowURNString:(NSString *)showURNString
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    PlaylistViewController *viewController = [storyboard instantiateInitialViewController];

    viewController.showURNString = showURNString;

    viewController.letterboxController.playlistDataSource = viewController.playlist;
    viewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
    viewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    viewController.letterboxController.globalHeaders = ApplicationSettingGlobalHeaders();
    
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
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:nil];
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ApplicationSettingServiceURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRTS];
    [[self.dataProvider latestEpisodesForShowWithURN:[SRGShowURN showURNWithString:self.showURNString] maximumPublicationMonth:nil completionBlock:^(SRGEpisodeComposition * _Nullable episodeComposition, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
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
        
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.letterboxController.playlistDataSource = self.playlist;
        
        [self.letterboxController playMedia:self.playlist.medias.firstObject withChaptersOnly:NO];
    }] resume];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
    }
}

#pragma mark Home indicator

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return self.letterboxView.userInterfaceHidden;
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, CGFloat heightOffset) {
        self.navigationController.navigationBarHidden = hidden;
    } completion:^(BOOL finished) {
        if (@available(iOS 11, *)) {
            [self setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
    }];
}

@end
