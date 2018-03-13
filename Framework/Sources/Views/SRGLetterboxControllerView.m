//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import "SRGLetterboxBaseView+Subclassing.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxView+Private.h"

@implementation SRGLetterboxControllerView

#pragma mark Object lifecycle

- (void)dealloc
{
    self.controller = nil;
}

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        [self willDetachFromController];
        
        _controller = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxMetadataDidChangeNotification
                                                      object:_controller];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackDidFailNotification
                                                      object:_controller];
        
        
        [self didDetachFromController];
    }
    
    if (controller) {
        [self willAttachToController];
        
        _controller = controller;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_letterbox_metadataDidChange:)
                                                     name:SRGLetterboxMetadataDidChangeNotification
                                                   object:controller];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_letterbox_playbackDidFail:)
                                                     name:SRGLetterboxPlaybackDidFailNotification
                                                   object:controller];
        
        [self didAttachToController];
    }
    
    [self metadataDidChange];
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self metadataDidChange];
    }
}

#pragma mark Subclassing hooks

- (void)willDetachFromController
{}

- (void)didDetachFromController
{}

- (void)willAttachToController
{}

- (void)didAttachToController
{}

- (void)metadataDidChange
{}

- (void)playbackDidFail
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

#pragma mark Layout

- (void)setNeedsLayoutAnimated:(BOOL)animated
{
    [self.contextView updateLayoutAnimated:animated];
}

#pragma mark Notifications

- (void)srg_letterbox_metadataDidChange:(NSNotification *)notification
{
    [self metadataDidChange];
}

- (void)srg_letterbox_playbackDidFail:(NSNotification *)notification
{
    [self playbackDidFail];
}

@end

@implementation UIView (SRGLetterboxControllerView)

- (void)srg_recursivelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [self updateLayoutInView:self forUserInterfaceHidden:userInterfaceHidden];
}

- (void)updateLayoutInView:(UIView *)view forUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    if ([view isKindOfClass:[SRGLetterboxControllerView class]]) {
        SRGLetterboxControllerView *controllerView = (SRGLetterboxControllerView *)view;
        [controllerView updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    }
    
    for (UIView *subview in view.subviews) {
        [self updateLayoutInView:subview forUserInterfaceHidden:userInterfaceHidden];
    }
}

@end
