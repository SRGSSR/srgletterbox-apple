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
        [self didAttachToController];
    }
}

#pragma mark Subclassing hooks

- (void)willUnattachFromController
{}

- (void)didAttachToController
{}

- (void)reloadData
{}

- (void)updateLayoutForView:(SRGLetterboxView *)view userInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
