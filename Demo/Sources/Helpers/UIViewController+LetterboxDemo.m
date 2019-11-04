//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+LetterboxDemo.h"

#import "ModalPlayerViewController.h"
#import "SettingsViewController.h"

#import <objc/runtime.h>

static void *s_dataProviderKey = &s_dataProviderKey;
static void *s_playlistKey = &s_playlistKey;

@interface UIViewController (LetterboxDemoPrivate)

@property (nonatomic) SRGDataProvider *letterbox_demo_dataProvider;
@property (nonatomic) Playlist *letterbox_demo_playlist;

@end

@implementation UIViewController (LetterboxDemo)

#pragma mark Getters and setters

- (SRGDataProvider *)letterbox_demo_dataProvider
{
    return objc_getAssociatedObject(self, s_dataProviderKey);
}

- (void)setLetterbox_demo_dataProvider:(SRGDataProvider *)dataProvider
{
    objc_setAssociatedObject(self, s_dataProviderKey, dataProvider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (Playlist *)letterbox_demo_playlist
{
    return objc_getAssociatedObject(self, s_playlistKey);
}

- (void)setLetterbox_demo_playlist:(Playlist *)playlist
{
    objc_setAssociatedObject(self, s_playlistKey, playlist, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Player presentation

- (void)openPlayerWithURN:(NSString *)URN
{
    [self openPlayerWithURN:URN serviceURL:nil];
}

- (void)openPlayerWithURN:(NSString *)URN serviceURL:(NSURL *)serviceURL
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    if (! serviceURL) {
        serviceURL = ApplicationSettingServiceURL();
    }
    
#if TARGET_OS_TV
    SRGLetterboxViewController *letterboxViewController = [[SRGLetterboxViewController alloc] init];
    letterboxViewController.controller.contentURLOverridingBlock = ^(NSString * _Nonnull URN) {
        return [URN isEqualToString:@"urn:rts:video:8806790"] ? [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"] : nil;
    };
    
    letterboxViewController.controller.serviceURL = serviceURL;
    letterboxViewController.controller.updateInterval = ApplicationSettingUpdateInterval();
    letterboxViewController.controller.globalParameters = ApplicationSettingGlobalParameters();
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = ApplicationSettingStandalone();
    settings.quality = ApplicationSettingPreferredQuality();
    
    if (ApplicationSettingAutoplayEnabled() && URN) {
        self.letterbox_demo_dataProvider = [[SRGDataProvider alloc] initWithServiceURL:serviceURL];
        [[self.letterbox_demo_dataProvider recommendedMediasForURN:URN userId:nil withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            self.letterbox_demo_playlist = [[Playlist alloc] initWithMedias:medias sourceUid:nil];
            self.letterbox_demo_playlist.continuousPlaybackTransitionDuration = 15.;
            letterboxViewController.controller.playlistDataSource = self.letterbox_demo_playlist;
        }] resume];
    }
    
    [letterboxViewController.controller playURN:URN atPosition:nil withPreferredSettings:settings];
    
    [self presentViewController:letterboxViewController animated:YES completion:nil];
#else
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN serviceURL:serviceURL];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    
    [self presentViewController:playerViewController animated:YES completion:nil];
#endif
}

@end
