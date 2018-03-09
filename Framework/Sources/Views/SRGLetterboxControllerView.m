//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import "SRGLetterboxView.h"

@implementation SRGLetterboxControllerView

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    [self willUpdateController];
    _controller = controller;
    [self didUpdateController];
    
    [self reloadData];
    [self srg_letterbox_updateLayout];
}

#pragma mark Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self srg_letterbox_updateLayout];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self reloadData];
    }
}

#pragma mark Helpers

- (void)srg_letterbox_updateLayout
{
    BOOL userInterfaceHidden = self.contextView ? self.contextView.userInterfaceHidden : YES;
    [self updateLayoutForUserInterfaceHidden:userInterfaceHidden];
}

#pragma mark Subclassing hooks

- (void)willUpdateController
{}

- (void)didUpdateController
{}

- (void)reloadData
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
