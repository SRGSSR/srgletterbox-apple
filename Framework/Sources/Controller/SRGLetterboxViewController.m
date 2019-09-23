//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxViewController.h"

#import "SRGLetterboxController+Private.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SRGLetterboxViewController () <SRGMediaPlayerViewControllerDelegate>

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) SRGMediaPlayerViewController *playerViewController;

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
        self.playerViewController = [[SRGMediaPlayerViewController alloc] initWithController:self.controller.mediaPlayerController];
        self.playerViewController.delegate = self;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(metadataDidChange:)
                                                   name:SRGLetterboxMetadataDidChangeNotification
                                                 object:controller];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(segmentDidStart:)
                                                   name:SRGMediaPlayerSegmentDidStartNotification
                                                 object:controller.mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(segmentDidEnd:)
                                                   name:SRGMediaPlayerSegmentDidEndNotification
                                                 object:controller.mediaPlayerController];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithController:nil];
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
}

#pragma mark SRGMediaPlayerViewControllerDelegate protocol

- (NSArray<AVMetadataItem *> *)playerViewControllerExternalMetadata:(SRGMediaPlayerViewController *)playerViewController
{
    SRGMedia *media = self.controller.subdivisionMedia ?: self.controller.fullLengthMedia;
    if (media) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
            titleItem.identifier = AVMetadataCommonIdentifierTitle;
            titleItem.value = media.title;
            titleItem.extendedLanguageTag = @"und";
            
            AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
            descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
            descriptionItem.value = media.summary;
            descriptionItem.extendedLanguageTag = @"und";
            
        #if 0
            AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
            artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
            artworkItem.value = UIImagePNGRepresentation([UIImage imageNamed:@"artwork"]);
            artworkItem.extendedLanguageTag = @"und";
        #endif
            
            return @[ titleItem.copy, descriptionItem.copy /*, artworkItem.copy */ ];
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
        
        AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
        descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
        descriptionItem.value = segment.summary;
        descriptionItem.extendedLanguageTag = @"und";
        
#if 0
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        artworkItem.value = UIImagePNGRepresentation([UIImage imageNamed:@"artwork"]);
        artworkItem.extendedLanguageTag = @"und";
#endif
        
        AVTimedMetadataGroup *navigationMarker = [[AVTimedMetadataGroup alloc] initWithItems:@[ titleItem.copy /*, artworkItem.copy */ ] timeRange:segment.srg_timeRange];
        [navigationMarkers addObject:navigationMarker];
    }
    
    return navigationMarkers.copy;
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self.playerViewController reloadData];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    [self.playerViewController reloadData];
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    [self.playerViewController reloadData];
}

@end
