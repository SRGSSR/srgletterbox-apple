//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MultiPlayerViewController.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface MultiPlayerViewController ()

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet SRGLetterboxView *smallLetterboxView1;
@property (nonatomic, weak) IBOutlet SRGLetterboxView *smallLetterboxView2;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;
@property (nonatomic) IBOutlet SRGLetterboxController *smallLetterboxController1;
@property (nonatomic) IBOutlet SRGLetterboxController *smallLetterboxController2;

@end

@implementation MultiPlayerViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:nil];
    
    self.smallLetterboxController1.muted = YES;
    self.smallLetterboxController1.tracked = NO;
    
    self.smallLetterboxController2.muted = YES;
    self.smallLetterboxController2.tracked = NO;
    
    [self.smallLetterboxView1 setUserInterfaceHidden:YES animated:NO togglable:NO];
    [self.smallLetterboxView2 setUserInterfaceHidden:YES animated:NO togglable:NO];
    
    UIGestureRecognizer *tapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchToStream1:)];
    [self.smallLetterboxView1 addGestureRecognizer:tapGestureRecognizer1];
    
    UIGestureRecognizer *tapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchToStream2:)];
    [self.smallLetterboxView2 addGestureRecognizer:tapGestureRecognizer2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:3608506"];
        [self.letterboxController playURN:URN];
        
        SRGMediaURN *URN1 = [SRGMediaURN mediaURNWithString:@"urn:rts:video:3608517"];
        [self.smallLetterboxController1 playURN:URN1];
        
        SRGMediaURN *URN2 = [SRGMediaURN mediaURNWithString:@"urn:rts:video:1967124"];
        [self.smallLetterboxController2 playURN:URN2];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        if (! self.letterboxController.pictureInPictureActive) {
            [self.letterboxController reset];
            [[SRGLetterboxService sharedService] disable];
        }
    }
}

#pragma mark Gesture recognizers

- (void)switchToStream1:(UIGestureRecognizer *)gestureRecognizer
{
    // Swap controllers
    SRGLetterboxController *tempLetterboxController = self.letterboxController;
    
    self.letterboxController = self.smallLetterboxController1;
    self.letterboxView.controller = self.smallLetterboxController1;
    
    self.smallLetterboxController1 = tempLetterboxController;
    self.smallLetterboxView1.controller = tempLetterboxController;
    
    self.letterboxController.muted = NO;
    self.letterboxController.tracked = YES;
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:nil];
    
    self.smallLetterboxController1.muted = YES;
    self.smallLetterboxController1.tracked = NO;
}

- (void)switchToStream2:(UIGestureRecognizer *)gestureRecognizer
{
    // Swap controllers
    SRGLetterboxController *tempLetterboxController = self.letterboxController;
    
    self.letterboxController = self.smallLetterboxController2;
    self.letterboxView.controller = self.smallLetterboxController2;
    
    self.smallLetterboxController2 = tempLetterboxController;
    self.smallLetterboxView2.controller = tempLetterboxController;
    
    self.letterboxController.muted = NO;
    self.letterboxController.tracked = YES;
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:nil];
    
    self.smallLetterboxController2.muted = YES;
    self.smallLetterboxController2.tracked = NO;
}

@end
