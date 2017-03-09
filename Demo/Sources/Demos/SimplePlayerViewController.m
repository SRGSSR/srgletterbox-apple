//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimplePlayerViewController.h"

@interface SimplePlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@end

@implementation SimplePlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    SimplePlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.URN = URN;
    return viewController;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:nil];
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
        [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
    }
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, CGFloat expansionHeight) {
        self.letterboxAspectRatioConstraint.constant = expansionHeight;
        [self.view layoutIfNeeded];
    } completion:nil];
}

@end
