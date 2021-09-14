//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Playlist.h"

#import "SettingsViewController.h"
#import "UIApplication+LetterboxDemo.h"
#import "UIWindow+LetterboxDemo.h"

@interface Playlist ()

@property (nonatomic) NSOrderedSet<SRGMedia *> *mediasSet;
@property (nonatomic, copy) NSString *sourceUid;
@property (nonatomic) NSInteger currentIndex;

@end

@implementation Playlist

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<SRGMedia *> *)medias sourceUid:(NSString *)sourceUid
{
    if (self = [super init]) {
        self.mediasSet = medias ? [NSOrderedSet orderedSetWithArray:medias] : nil;
        self.continuousPlaybackTransitionDuration = SRGLetterboxContinuousPlaybackDisabled;
        self.sourceUid = sourceUid;
    }
    return self;
}

#pragma mark Getters and setters

- (NSArray<SRGMedia *> *)medias
{
    return self.mediasSet.array;
}

#pragma SRGLetterboxControllerPlaylistDataSource protocol

- (SRGMedia *)previousMediaForController:(SRGLetterboxController *)controller
{
    if (self.currentIndex != NSNotFound) {
        return (self.currentIndex > 0) ? self.mediasSet[self.currentIndex - 1] : nil;
    }
    else {
        return nil;
    }
}

- (SRGMedia *)nextMediaForController:(SRGLetterboxController *)controller
{
    if (self.currentIndex != NSNotFound) {
        return (self.currentIndex < self.mediasSet.count - 1) ? self.mediasSet[self.currentIndex + 1] : nil;
    }
    else {
        return self.mediasSet.firstObject;
    }
}

- (void)controller:(SRGLetterboxController *)controller didChangeToMedia:(SRGMedia *)media
{
    self.currentIndex = [self.mediasSet indexOfObject:media];
}

- (SRGLetterboxPlaybackSettings *)controller:(SRGLetterboxController *)controller preferredSettingsForMedia:(SRGMedia *)media
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
#if TARGET_OS_IOS
    settings.standalone = ApplicationSettingStandalone();
    settings.quality = ApplicationSettingPreferredQuality();
#endif
    settings.sourceUid = self.sourceUid;
    return settings;
}

#pragma mark SRGLetterboxControllerPlaybackTransitionDelegate protocol

- (NSTimeInterval)continuousPlaybackTransitionDurationForController:(SRGLetterboxController *)controller
{
    return self.continuousPlaybackTransitionDuration;
}

- (void)controllerDidEndPlaybackdWithoutTransition:(SRGLetterboxController *)controller
{
#if TARGET_OS_TV
    // For example, on tvOS, we might want to automatically close the player if nothing follows.
    UIViewController *topViewController = UIApplication.sharedApplication.letterbox_demo_mainWindow.letterbox_demo_topViewController;
    if ([topViewController isKindOfClass:SRGLetterboxViewController.class]) {
        [topViewController dismissViewControllerAnimated:YES completion:nil];
    }
#endif
}

@end
