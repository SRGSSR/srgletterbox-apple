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
    SRGMedia *media = self.controller.fullLengthMedia;
    if (media) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
        titleItem.identifier = AVMetadataCommonIdentifierTitle;
        titleItem.value = media.title;
        titleItem.extendedLanguageTag = @"und";
        
        AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
        descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
        descriptionItem.value = media.summary;
        descriptionItem.extendedLanguageTag = @"und";
        
        // TODO: Off the main thread + dimensions + default image if none
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        NSURL *imageURL = [media imageURLForDimension:SRGImageDimensionWidth withValue:500.f type:SRGImageTypeDefault];
        artworkItem.value = [NSData dataWithContentsOfURL:imageURL];
        artworkItem.extendedLanguageTag = @"und";
        
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
        
        AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
        descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
        descriptionItem.value = segment.summary;
        descriptionItem.extendedLanguageTag = @"und";
        
        // TODO: Off the main thread + dimensions + default image if none
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        NSURL *imageURL = [segment imageURLForDimension:SRGImageDimensionWidth withValue:500.f type:SRGImageTypeDefault];
        artworkItem.value = [NSData dataWithContentsOfURL:imageURL];
        artworkItem.extendedLanguageTag = @"und";
        
        AVTimedMetadataGroup *navigationMarker = [[AVTimedMetadataGroup alloc] initWithItems:@[ titleItem.copy, artworkItem.copy ] timeRange:segment.srg_timeRange];
        [navigationMarkers addObject:navigationMarker];
    }
    
    return navigationMarkers.copy;
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self.playerViewController reloadData];
}

@end
