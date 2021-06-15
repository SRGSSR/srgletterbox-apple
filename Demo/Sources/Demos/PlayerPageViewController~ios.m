//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayerPageViewController.h"

#import "NSBundle+LetterboxDemo.h"
#import "SettingsViewController.h"

@import SRGLetterbox;

@interface PlayerPageViewController ()

@property (nonatomic, copy) NSString *URN;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained

@end

@implementation PlayerPageViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(NSString *)URN
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LetterboxDemoResourceNameForUIClass(self.class) bundle:nil];
    PlayerPageViewController *viewController = [storyboard instantiateInitialViewController];
    
    viewController.URN = URN;
    
    viewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
    viewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    viewController.letterboxController.globalHeaders = ApplicationSettingGlobalParameters();
    
    return viewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.letterboxView setUserInterfaceHidden:YES animated:NO];
    [self.letterboxView setTimelineAlwaysHidden:YES animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = ApplicationSettingStandalone();
    settings.quality = ApplicationSettingPreferredQuality();
    
    [self.letterboxController playURN:self.URN atPosition:nil withPreferredSettings:settings];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.letterboxController stop];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.letterboxController reset];
}

#pragma mark Home indicator

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return self.letterboxView.userInterfaceHidden;
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:nil completion:^(BOOL finished) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }];
}

@end
