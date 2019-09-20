//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxViewController.h"

#import "SRGLetterboxController+Private.h"

@interface SRGLetterboxViewController ()

@property (nonatomic) SRGLetterboxController *letterboxController;

@end

@implementation SRGLetterboxViewController

#pragma mark Object lifecycle

- (instancetype)initWithLetterboxController:(SRGLetterboxController *)letterboxController
{
    if (! letterboxController) {
        letterboxController = [[SRGLetterboxController alloc] init];
    }
    
    if (self = [super initWithController:letterboxController.mediaPlayerController]) {
        self.letterboxController = letterboxController;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithLetterboxController:nil];
}

@end
