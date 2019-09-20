//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxViewController.h"

#import "SRGLetterboxController+Private.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SRGLetterboxViewController ()

@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) SRGMediaPlayerViewController *playerViewController;

@end

@implementation SRGLetterboxViewController

#pragma mark Object lifecycle

- (instancetype)initWithController:(SRGLetterboxController *)controller
{
    if (self = [super init]) {
        if (! controller) {
            controller = [[SRGLetterboxController alloc] init];
        }
        self.controller = controller;
        self.playerViewController = [[SRGMediaPlayerViewController alloc] initWithController:self.controller.mediaPlayerController];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithController:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *playerView = self.playerViewController.view;
    playerView.frame = self.view.bounds;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:playerView];
    
    [self addChildViewController:self.playerViewController];
}

@end
