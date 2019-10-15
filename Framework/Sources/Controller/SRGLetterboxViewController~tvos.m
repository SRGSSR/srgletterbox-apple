//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxViewController.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGAvailabilityView.h"
#import "SRGErrorView.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxContentProposalViewController.h"
#import "UIImage+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <YYWebImage/YYWebImage.h>

static UIView *SRGLetterboxViewControllerLoadingIndicatorSubview(UIView *view)
{
    if ([NSStringFromClass(view.class) containsString:@"LoadingIndicator"]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *loadingView = SRGLetterboxViewControllerLoadingIndicatorSubview(subview);
        if (loadingView) {
            return loadingView;
        }
    }
    
    return nil;
}

@interface SRGLetterboxViewController () <SRGMediaPlayerViewControllerDelegate>

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) SRGMediaPlayerViewController *playerViewController;

@property (nonatomic) NSMutableDictionary<NSURL *, YYWebImageOperation *> *imageOperations;

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) SRGAvailabilityView *availabilityView;
@property (nonatomic, weak) SRGErrorView *errorView;
@property (nonatomic, weak) UIImageView *loadingImageView;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SRGLetterboxViewController

#pragma mark Object lifecycle

- (instancetype)initWithController:(SRGLetterboxController *)controller
{
    if (self = [super init]) {
        if (! controller) {
            controller = [[SRGLetterboxController alloc] init];
        }
        
        self.controller = controller;
        self.playerViewController = [[SRGMediaPlayerViewController alloc] initWithController:controller.mediaPlayerController];
        self.playerViewController.delegate = self;
        
        self.imageOperations = [NSMutableDictionary dictionary];
        
        @weakify(self)
        @weakify(controller)
        self.periodicTimeObserver = [controller addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            @strongify(controller);
            
            AVPlayerItem *playerItem = controller.mediaPlayerController.player.currentItem;
            
            if (@available(tvOS 10, *)) {
                NSTimeInterval transitionDuration = SRGLetterboxContinuousPlaybackDisabled;
                if ([controller.playlistDataSource respondsToSelector:@selector(continuousPlaybackTransitionDurationForController:)]) {
                    transitionDuration = [controller.playlistDataSource continuousPlaybackTransitionDurationForController:controller];
                }
                
                // Continuous playback transition is managed at the controller level when playback end is reached. We therefore
                // display the content proposal at the very end of the media. For the same reason we must also not set any
                // `automaticAcceptanceInterval` on the `AVContentProposal`.
                SRGMedia *nextMedia = controller.nextMedia;
                if (transitionDuration != SRGLetterboxContinuousPlaybackDisabled && nextMedia) {
                    playerItem.nextContentProposal = [[AVContentProposal alloc] initWithContentTimeForTransition:kCMTimeZero
                                                                                                           title:nextMedia.title
                                                                                                    previewImage:nil];
                }
                else {
                    playerItem.nextContentProposal = nil;
                }
            }
            
            [self updateMainLayout];
            [self reloadImage];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(metadataDidChange:)
                                                   name:SRGLetterboxMetadataDidChangeNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackStateDidChange:)
                                                   name:SRGLetterboxPlaybackStateDidChangeNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackDidFail:)
                                                   name:SRGLetterboxPlaybackDidFailNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(playbackDidContinueAutomatically:)
                                                   name:SRGLetterboxPlaybackDidContinueAutomaticallyNotification
                                                 object:controller];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithController:nil];
}

- (void)dealloc
{
    [self.imageOperations enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull URL, YYWebImageOperation * _Nonnull operation, BOOL * _Nonnull stop) {
        [operation cancel];
    }];
    [self.controller removePeriodicTimeObserver:self.periodicTimeObserver];
    [self.playerViewController removeFromParentViewController];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *playerView = self.playerViewController.view;
    playerView.frame = self.view.bounds;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:playerView];
    [self addChildViewController:self.playerViewController];
    
    SRGErrorView *errorView = [[SRGErrorView alloc] initWithFrame:playerView.bounds];
    errorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    errorView.controller = self.controller;
    [playerView insertSubview:errorView atIndex:0];
    self.errorView = errorView;
    
    SRGAvailabilityView *availabilityView = [[SRGAvailabilityView alloc] initWithFrame:playerView.bounds];
    availabilityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    availabilityView.controller = self.controller;
    [playerView insertSubview:availabilityView atIndex:0];
    self.availabilityView = availabilityView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:playerView.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [playerView insertSubview:imageView atIndex:0];
    self.imageView = imageView;
    
    UIView *loadingIndicatorView = SRGLetterboxViewControllerLoadingIndicatorSubview(playerView);
    loadingIndicatorView.alpha = 0.f;
    
    UIImageView *loadingImageView = [UIImageView srg_loadingImageViewWithTintColor:UIColor.whiteColor];
    loadingImageView.alpha = 0.f;
    [playerView addSubview:loadingImageView];
    self.loadingImageView = loadingImageView;
    
    loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[ [loadingImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                               [loadingImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor] ]];
    
    [self updateMainLayout];
    [self reloadData];
}

#pragma mark Image retrieval

- (UIImage *)imageForMetadata:(id<SRGImageMetadata>)metadata withCompletion:(void (^)(void))completion
{
    NSParameterAssert(completion);
    
    YYWebImageManager *webImageManager = [YYWebImageManager sharedManager];
    
    CGSize size = SRGSizeForImageScale(SRGImageScaleMedium);
    NSURL *imageURL = [metadata imageURLForDimension:SRGImageDimensionWidth withValue:size.width type:SRGImageTypeDefault];
    NSString *key = [webImageManager cacheKeyForURL:imageURL];
    UIImage *image = [webImageManager.cache getImageForKey:key];
    if (image) {
        return image;
    }
    
    if (! self.imageOperations[imageURL]) {
        YYWebImageOperation *imageOperation = [webImageManager requestImageWithURL:imageURL options:0 progress:nil transform:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageOperations[imageURL] = nil;
                completion();
            });
        }];
        self.imageOperations[imageURL] = imageOperation;
    }
    
    return [UIImage srg_vectorImageAtPath:SRGLetterboxMediaPlaceholderFilePath() withSize:size];
}

#pragma mark Data

- (void)reloadData
{
    [self.playerViewController reloadData];
    [self reloadImage];
}

- (NSString *)fullSummaryForMedia:(SRGMedia *)media
{
    NSParameterAssert(media);
    
    if (media.summary && media.imageCopyright) {
        NSString *imageCopyright = [NSString stringWithFormat:SRGLetterboxLocalizedString(@"Image credit: %@", @"Image copyright introductory label"), media.imageCopyright];
        return [NSString stringWithFormat:@"%@\n\n%@", media.summary, imageCopyright];
    }
    else if (media.imageCopyright) {
        return [NSString stringWithFormat:SRGLetterboxLocalizedString(@"Image credit: %@", @"Image copyright introductory label"), media.imageCopyright];
    }
    else {
        return media.summary;
    }
}

- (void)reloadImage
{
    [self.imageView srg_requestImageForController:self.controller withScale:SRGImageScaleLarge type:SRGImageTypeDefault atDate:self.controller.date];
}

#pragma mark Layout

- (void)updateMainLayout
{
    SRGMediaPlayerPlaybackState playbackState = self.controller.playbackState;
    BOOL playerViewVisible = (self.controller.media.mediaType == SRGMediaTypeVideo && playbackState != SRGMediaPlayerPlaybackStateIdle && playbackState != SRGMediaPlayerPlaybackStatePreparing && playbackState != SRGMediaPlayerPlaybackStateEnded);
    self.imageView.alpha = playerViewVisible ? 0.f : 1.f;
    
    NSError *error = self.controller.error;
    if ([error.domain isEqualToString:SRGLetterboxErrorDomain] && error.code == SRGLetterboxErrorCodeNotAvailable) {
        self.errorView.alpha = 0.f;
        self.availabilityView.alpha = 1.f;
        self.view.userInteractionEnabled = NO;
    }
    else if (error) {
        self.errorView.alpha = 1.f;
        self.availabilityView.alpha = 0.f;
        self.view.userInteractionEnabled = NO;
    }
    else {
        self.errorView.alpha = 0.f;
        self.availabilityView.alpha = 0.f;
        self.view.userInteractionEnabled = (self.controller.URN != nil);
    }
    
    if (self.controller.loading) {
        self.loadingImageView.alpha = 1.f;
        [self.loadingImageView startAnimating];
    }
    else {
        self.loadingImageView.alpha = 0.f;
        [self.loadingImageView stopAnimating];
    }
}

#pragma mark AVPlayerViewControllerDelegate protocol

- (BOOL)playerViewController:(AVPlayerViewController *)playerViewController shouldPresentContentProposal:(AVContentProposal *)proposal API_AVAILABLE(tvos(10.0))
{
    SRGLetterboxController *controller = self.controller;
    if (controller.nextMedia) {
        playerViewController.contentProposalViewController = [[SRGLetterboxContentProposalViewController alloc] initWithController:controller];
        return YES;
    }
    else {
        playerViewController.contentProposalViewController = nil;
        return NO;
    }
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController didAcceptContentProposal:(AVContentProposal *)proposal API_AVAILABLE(tvos(10.0))
{
    if ([self.delegate respondsToSelector:@selector(letterboxViewController:didEngageInContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxViewController:self didEngageInContinuousPlaybackWithUpcomingMedia:self.controller.nextMedia];
    }
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController didRejectContentProposal:(AVContentProposal *)proposal API_AVAILABLE(tvos(10.0))
{
    if ([self.delegate respondsToSelector:@selector(letterboxViewController:didCancelContinuousPlaybackWithUpcomingMedia:)]) {
        [self.delegate letterboxViewController:self didCancelContinuousPlaybackWithUpcomingMedia:self.controller.nextMedia];
    }
    
    [self.controller cancelContinuousPlayback];
}

#pragma mark SRGMediaPlayerViewControllerDelegate protocol

- (NSArray<AVMetadataItem *> *)playerViewControllerExternalMetadata:(SRGMediaPlayerViewController *)playerViewController
{
    SRGMedia *media = self.controller.fullLengthMedia;
    if (media) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
        titleItem.identifier = AVMetadataCommonIdentifierTitle;
        titleItem.value = media.title;
        titleItem.extendedLanguageTag = @"und";
        
        AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
        descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
        descriptionItem.value = [self fullSummaryForMedia:media];
        descriptionItem.extendedLanguageTag = @"und";
        
        UIImage *image = [self imageForMetadata:media withCompletion:^{
            [self reloadData];
        }];
        
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        artworkItem.value = UIImagePNGRepresentation(image);
        artworkItem.extendedLanguageTag = @"und";       // Also required for images in external metadata
        
        return @[ titleItem.copy, descriptionItem.copy, artworkItem.copy ];
    }
    else {
        return nil;
    }
}

- (NSArray<AVTimedMetadataGroup *> *)playerViewController:(SRGMediaPlayerViewController *)playerViewController navigationMarkersForSegments:(NSArray<id<SRGSegment>> *)segments
{
    NSMutableArray<AVTimedMetadataGroup *> *navigationMarkers = [NSMutableArray array];
    
    for (SRGSegment *segment in self.controller.mediaComposition.mainChapter.segments) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
        titleItem.identifier = AVMetadataCommonIdentifierTitle;
        titleItem.value = segment.title;
        titleItem.extendedLanguageTag = @"und";
        
        UIImage *image = [self imageForMetadata:segment withCompletion:^{
            [self reloadData];
        }];
        
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        artworkItem.value = UIImagePNGRepresentation(image);
        artworkItem.extendedLanguageTag = @"und";       // Apparently not required, but added for safety / consistency
        
        AVTimedMetadataGroup *navigationMarker = [[AVTimedMetadataGroup alloc] initWithItems:@[ titleItem.copy, artworkItem.copy ] timeRange:segment.srg_timeRange];
        [navigationMarkers addObject:navigationMarker];
    }
    
    return navigationMarkers.copy;
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self reloadData];
}

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self updateMainLayout];
}

- (void)playbackDidFail:(NSNotification *)notification
{
    [self updateMainLayout];
}

- (void)playbackDidContinueAutomatically:(NSNotification *)notification
{
    if (@available(tvOS 10, *)) {
        [self.playerViewController.contentProposalViewController dismissContentProposalForAction:AVContentProposalActionAccept animated:YES completion:^{
            self.playerViewController.contentProposalViewController = nil;
        }];
    }
}

@end
