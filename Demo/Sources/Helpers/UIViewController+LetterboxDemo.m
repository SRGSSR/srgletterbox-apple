//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+LetterboxDemo.h"

#import "AdvancedPlayerViewController.h"
#import "SettingsViewController.h"

@import SRGDataProviderNetwork;

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
    [self openPlayerWithURN:URN media:nil serviceURL:nil];
}

- (void)openPlayerWithURN:(NSString *)URN serviceURL:(NSURL *)serviceURL
{
    [self openPlayerWithURN:URN media:nil serviceURL:serviceURL];
}

- (void)openPlayerWithMedia:(SRGMedia *)media serviceURL:(NSURL *)serviceURL
{
    [self openPlayerWithURN:media.URN media:media serviceURL:serviceURL];
}

- (void)openPlayerWithURN:(NSString *)URN media:(SRGMedia *)media serviceURL:(NSURL *)serviceURL
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    if (! serviceURL) {
        serviceURL = ApplicationSettingServiceURL();
    }
    
    if (! ApplicationSettingPrefersMediaContentEnabled()) {
        media = nil;
    }
    
    // If `media` is set, `URN` is ignored.
    if (media) {
        URN = media.URN;
    }
    
#if TARGET_OS_TV
    SRGLetterboxViewController *letterboxViewController = [[SRGLetterboxViewController alloc] init];
    letterboxViewController.controller.contentURLOverridingBlock = ^(NSString * _Nonnull URN) {
        NSURL *overriddenURL = nil;
        if ([URN isEqualToString:@"urn:rts:video:8806790"]) {
            overriddenURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
        }
        else if ([URN isEqualToString:@"urn:rts:audio:8798735"]) {
            overriddenURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8"];
        }
        return overriddenURL;
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
    
    if (media) {
        [letterboxViewController.controller playMedia:media atPosition:nil withPreferredSettings:settings];
    }
    else {
        [letterboxViewController.controller playURN:URN atPosition:nil withPreferredSettings:settings];
    }
    
    [self presentViewController:letterboxViewController animated:YES completion:nil];
#else
    void (^openModalPlayer)(void) = ^{
        AdvancedPlayerViewController *playerViewController = [[AdvancedPlayerViewController alloc] initWithURN:URN media:media serviceURL:serviceURL];
        playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
        // (might happen if presenting and dismissing fast)
        if (playerViewController.presentingViewController) {
            return;
        }
        
        [self presentViewController:playerViewController animated:YES completion:nil];
    };
    
    if (@available(iOS 13, *)) {
        // Long-form is usually associated with videos, but we have no way to know which kind of content will be played
        // (URNs are opaque). This is not a problem, though, as AirPlay support is available for all content types.
        [AVAudioSession.sharedInstance prepareRouteSelectionForPlaybackWithCompletionHandler:^(BOOL shouldStartPlayback, AVAudioSessionRouteSelection routeSelection) {
            if (shouldStartPlayback && routeSelection != AVAudioSessionRouteSelectionNone) {
                openModalPlayer();
            }
        }];
    }
    else {
        openModalPlayer();
    }
#endif
}

@end
