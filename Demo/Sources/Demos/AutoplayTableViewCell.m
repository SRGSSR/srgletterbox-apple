//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AutoplayTableViewCell.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface AutoplayTableViewCell ()

@property (nonatomic) SRGLetterboxController *letterboxController;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;

@end

@implementation AutoplayTableViewCell

#pragma mark Getters and setters

- (void)setMedia:(SRGMedia *)media
{
    _media = media;
    
    if (media) {
        [self.letterboxController playMedia:media];
    }
    else {
        [self.letterboxController reset];
    }
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        self.letterboxController = [[SRGLetterboxController alloc] init];
        self.letterboxView.controller = self.letterboxController;
    }
    else {
        [self.letterboxController reset];
    }
}

@end
