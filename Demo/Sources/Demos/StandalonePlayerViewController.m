//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "StandalonePlayerViewController.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface StandalonePlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UISwitch *mirroredSwitch;

@end

@implementation StandalonePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    StandalonePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.URN = URN;
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
    
    self.mirroredSwitch.on = [SRGLetterboxService sharedService].mirroredOnExternalScreen;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        [self.letterboxController playURN:self.URN];
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

#pragma mark Actions

- (IBAction)useForService:(id)sender
{
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:nil];
}

- (IBAction)resetService:(id)sender
{
    [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
}

- (IBAction)toggleMirrored:(id)sender
{
    [SRGLetterboxService sharedService].mirroredOnExternalScreen = ! [SRGLetterboxService sharedService].mirroredOnExternalScreen;
}

@end
