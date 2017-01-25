//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalPlayerViewController.h"

#import <Masonry/Masonry.h>

static const UILayoutPriority LetterboxViewConstraintLessPriority = 850;
static const UILayoutPriority LetterboxViewConstraintMorePriority = 950;

@interface ModalPlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

// Switching to and from full-screen is made by adjusting the priority / constance of a constraint of the letterbox
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxLeadingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterbox169Constraint;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Ensure consistent constraint constant values with the associated storyboard
    [self letterboxView:self.letterboxView didToggleFullScreen:NO animated:NO];
    
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
}

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

- (void)letterboxView:(SRGLetterboxView *)letterboxView didToggleFullScreen:(BOOL)isFullScreen animated:(BOOL)animated
{
    [self.view layoutIfNeeded];
    
    void (^animations)(void) = ^{
        if (isFullScreen) {
            self.letterboxLeadingConstraint.constant = 0.f;
            self.letterboxTrailingConstraint.constant = 0.f;
            self.letterboxTopConstraint.constant = 0.f;
            
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintMorePriority;
            self.letterbox169Constraint.priority = LetterboxViewConstraintLessPriority;
        }
        else {
            self.letterboxLeadingConstraint.constant = 16.f;
            self.letterboxTrailingConstraint.constant = 16.f;
            self.letterboxTopConstraint.constant = 30.f;
            
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintLessPriority;
            self.letterbox169Constraint.priority = LetterboxViewConstraintMorePriority;
        }
        
        [self setNeedsStatusBarAppearanceUpdate];
        [self.view layoutIfNeeded];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            animations();
        }];
    }
    else {
        animations();
    }
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)hideControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:YES animated:YES togglable:YES];
}

- (IBAction)showControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:NO animated:YES togglable:YES];
}

- (IBAction)forceHideControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:YES animated:YES togglable:NO];
}

- (IBAction)forceShowControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:NO animated:YES togglable:NO];
}

- (IBAction)fullScreen:(id)sender
{
    [self.letterboxView setFullScreen:YES animated:YES];
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return (self.letterboxView) ? self.letterboxView.isFullScreen : NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

@end
