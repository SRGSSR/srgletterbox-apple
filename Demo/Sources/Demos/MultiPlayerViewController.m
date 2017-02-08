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

@property (nonatomic) SRGLetterboxController *smallLetterboxController1;
@property (nonatomic) SRGLetterboxController *smallLetterboxController2;

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
    
    self.letterboxView.controller = [SRGLetterboxService sharedService].controller;
    
    self.smallLetterboxController1 = [[SRGLetterboxController alloc] init];
    self.smallLetterboxController2 = [[SRGLetterboxController alloc] init];
    
    self.smallLetterboxView1.controller = self.smallLetterboxController1;
    self.smallLetterboxView2.controller = self.smallLetterboxController2;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:3608506"];
        [[SRGLetterboxService sharedService].controller playURN:URN withPreferredQuality:SRGQualityNone];
        
        SRGMediaURN *URN1 = [SRGMediaURN mediaURNWithString:@"urn:rts:video:3608517"];
        [self.smallLetterboxController1 playURN:URN1 withPreferredQuality:SRGQualityNone];
        
        SRGMediaURN *URN2 = [SRGMediaURN mediaURNWithString:@"urn:rts:video:1967124"];
        [self.smallLetterboxController2 playURN:URN2 withPreferredQuality:SRGQualityNone];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        if (! [SRGLetterboxService sharedService].pictureInPictureActive) {
            [[SRGLetterboxService sharedService].controller reset];
        }
    }
}

@end
