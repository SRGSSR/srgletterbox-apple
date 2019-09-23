//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxViewController.h"

#import "SRGLetterboxController+Private.h"
#import "UIImage+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <YYWebImage/YYWebImage.h>

@interface SRGLetterboxViewController () <SRGMediaPlayerViewControllerDelegate>

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) SRGMediaPlayerViewController *playerViewController;

@property (nonatomic) NSMutableDictionary<NSURL *, YYWebImageOperation *> *imageOperations;

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
        
        self.imageOperations = [NSMutableDictionary dictionary];
        
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

- (void)dealloc
{
    [self.imageOperations enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull URL, YYWebImageOperation * _Nonnull operation, BOOL * _Nonnull stop) {
        [operation cancel];
    }];
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
        
        UIImage *image = [self imageForMetadata:media withCompletion:^{
            [self.playerViewController reloadData];
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
        
        AVMutableMetadataItem *descriptionItem = [[AVMutableMetadataItem alloc] init];
        descriptionItem.identifier = AVMetadataCommonIdentifierDescription;
        descriptionItem.value = segment.summary;
        descriptionItem.extendedLanguageTag = @"und";
        
        UIImage *image = [self imageForMetadata:segment withCompletion:^{
            [self.playerViewController reloadData];
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
    [self.playerViewController reloadData];
}

@end
