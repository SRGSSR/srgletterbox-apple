//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

@implementation SRGLetterboxControllerView

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        [self willUnattachFromController];
    }
    
    _controller = controller;
    
    if (controller) {
        [self didAttachToControlller];
    }
}

#pragma mark Subclassing hooks

- (void)willUnattachFromController
{}

- (void)didAttachToControlller
{}

- (void)reloadData
{}

- (void)updateLayoutForController:(SRGLetterboxController *)controller view:(SRGLetterboxView *)view userInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
