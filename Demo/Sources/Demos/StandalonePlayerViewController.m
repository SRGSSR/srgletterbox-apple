//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "StandalonePlayerViewController.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface StandalonePlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;

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
    return [self initWithURN:nil];
}

#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        if (self.URN) {
            [self.letterboxController playURN:self.URN withPreferredQuality:SRGQualityNone];
        }
        else {
            self.letterboxController = [SRGLetterboxService sharedService].controller;
            self.letterboxView.controller = self.letterboxController;
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        // FIXME: Won't work, should ask the controller itself
        if (! [SRGLetterboxService sharedService].pictureInPictureActive) {
            [self.letterboxController reset];
        }
    }
}

#pragma mark Actions

- (IBAction)useForService:(id)sender
{
    [SRGLetterboxService sharedService].controller = self.letterboxController;
}

- (IBAction)resetService:(id)sender
{
    [SRGLetterboxService sharedService].controller = [[SRGLetterboxController alloc] init];
}

@end
