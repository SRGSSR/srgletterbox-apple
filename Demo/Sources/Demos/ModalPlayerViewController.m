//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalPlayerViewController.h"

@interface ModalPlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@end

@implementation ModalPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    ModalPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.URN = URN;
    return viewController;
}

- (instancetype)init
{
    return [self initWithURN:nil];
}

#pragma mark View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        if (self.URN) {
            [[SRGLetterboxService sharedService] playURN:self.URN withPreferredQuality:SRGQualityHD];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        SRGLetterboxService *service = [SRGLetterboxService sharedService];
        if (! service.pictureInPictureActive) {
            [service reset];
        }
    }
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden) {
        self.closeButton.alpha = hidden ? 0.f : 1.f;
    } completion:nil];
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
