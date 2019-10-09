//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+LetterboxDemo.h"

#import "SettingsViewController.h"

#if TARGET_OS_IOS
#import "ModalPlayerViewController.h"
#endif

@interface UIViewController (LetterboxDemoPrivate) <SRGLetterboxViewControllerDelegate>

@end

@implementation UIViewController (LetterboxDemo)

- (void)openPlayerWithURN:(NSString *)URN serviceURL:(nullable NSURL *)serviceURL updateInterval:(nullable NSNumber *)updateInterval
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    UIViewController *viewController = nil;
    
#if TARGET_OS_IOS
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN serviceURL:serviceURL updateInterval:updateInterval];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    
    viewController = playerViewController;
#else
    SRGLetterboxViewController *letterboxViewController = [[SRGLetterboxViewController alloc] init];
    letterboxViewController.delegate = self;
    letterboxViewController.controller.contentURLOverridingBlock = ^(NSString * _Nonnull URN) {
        return [URN isEqualToString:@"urn:rts:video:8806790"] ? [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"] : nil;
    };
    
    letterboxViewController.controller.serviceURL = serviceURL ?: ApplicationSettingServiceURL();
    letterboxViewController.controller.updateInterval = updateInterval ? updateInterval.doubleValue : ApplicationSettingUpdateInterval();
    letterboxViewController.controller.globalParameters = ApplicationSettingGlobalParameters();
    
    [letterboxViewController.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    if (URN && [self conformsToProtocol:@protocol(SRGLetterboxDemoTVOSContinuePlayback)]) {
        UIViewController<SRGLetterboxDemoTVOSContinuePlayback> *viewController = (UIViewController<SRGLetterboxDemoTVOSContinuePlayback> *)self;
        viewController.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
        [[viewController.dataProvider recommendedMediasForURN:URN userId:nil withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            viewController.playlist = [[Playlist alloc] initWithMedias:medias sourceUid:nil];
            viewController.playlist.continuousPlaybackTransitionDuration = 30.;
            letterboxViewController.controller.playlistDataSource = viewController.playlist;
        }] resume];
    }
    
    viewController = letterboxViewController;
#endif
    
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark SRGLetterboxViewControllerDelegate protocol

- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
