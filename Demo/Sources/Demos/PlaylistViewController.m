//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlaylistViewController.h"

#import "Playlist.h"
#import "SettingsViewController.h"
#import "UIWindow+LetterboxDemo.h"

#import <libextobjc/libextobjc.h>

@interface PlaylistViewController ()

@property (nonatomic) SRGShowURN *showURN;
@property (nonatomic) Playlist *playlist;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic) SRGDataProvider *dataProvider;

@end

@implementation PlaylistViewController

#pragma mark Object lifecycle

- (instancetype)initWithShowURN:(SRGShowURN *)showURN
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    PlaylistViewController *viewController = [storyboard instantiateInitialViewController];

    viewController.showURN = showURN;

    viewController.letterboxController.playlistDataSource = viewController.playlist;
    viewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
    viewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    viewController.letterboxController.globalHeaders = ApplicationSettingGlobalHeaders();
    viewController.letterboxController.continuousPlaybackDelay = 10.;
    
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
    
    self.letterboxView.controller = self.letterboxController;
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ApplicationSettingServiceURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRTS];
    [[self.dataProvider latestEpisodesForShowWithURN:self.showURN maximumPublicationMonth:nil completionBlock:^(SRGEpisodeComposition * _Nullable episodeComposition, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
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
        if (! self.letterboxController.pictureInPictureActive) {
            [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
        }
    }
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark Home indicator

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return self.letterboxView.userInterfaceHidden;
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.topViewController;
    return topViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.topViewController;
    [topViewController presentViewController:self animated:YES completion:^{
        completionHandler(YES);
    }];
}

- (void)letterboxDidStopPlaybackFromPictureInPicture
{
    [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, CGFloat heightOffset) {
        self.letterboxAspectRatioConstraint.constant = heightOffset;
    } completion:^(BOOL finished) {
        if (@available(iOS 11, *)) {
            [self setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
    }];
}

#pragma mark Actions

- (IBAction)playPreviousMedia:(id)sender
{
    [self.letterboxController playPreviousMedia];
}

- (IBAction)playNextMedia:(id)sender
{
    [self.letterboxController playNextMedia];
}

- (IBAction)toggleView:(id)sender
{
    if (self.letterboxView.controller) {
        self.letterboxView.controller = nil;
    }
    else {
        self.letterboxView.controller = self.letterboxController;
    }
}

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
