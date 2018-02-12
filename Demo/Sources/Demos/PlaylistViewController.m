//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlaylistViewController.h"

#import "Playlist.h"
#import "SettingsViewController.h"
#import "UIWindow+LetterboxDemo.h"

@interface PlaylistViewController ()

@property (nonatomic) Playlist *playlist;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *marginConstraints;

@end

@implementation PlaylistViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<SRGMedia *> *)medias
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    PlaylistViewController *viewController = [storyboard instantiateInitialViewController];

    viewController.playlist = [[Playlist alloc] initWithMedias:medias];

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
    
    self.letterboxController.playlistDataSource = self.playlist;
    
    self.letterboxView.controller = self.letterboxController;
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    SRGMedia *firstMedia = self.playlist.medias.firstObject;
    if (firstMedia) {
        [self.letterboxController playMedia:firstMedia withChaptersOnly:NO];
    }
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
        [self.view layoutIfNeeded];
    } completion:nil];
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

- (IBAction)changeMargins:(UISlider *)slider
{
    [self.marginConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = slider.value;
    }];
}

@end
