//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import "SRGLetterboxView.h"

@interface SRGLetterboxControllerView ()

@property (nonatomic, readonly) SRGLetterboxView *srg_letterbox_parentView;

@end

@implementation SRGLetterboxControllerView

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    _controller = controller;
    
    [self didAttach];
    [self reloadData];
    [self srg_letterbox_updateLayout];
}

- (SRGLetterboxView *)srg_letterbox_parentView
{
    UIView *parentView = self.superview;
    while (parentView) {
        if ([parentView isKindOfClass:[SRGLetterboxView class]]) {
            return (SRGLetterboxView *)parentView;
        }
        parentView = parentView.superview;
    }
    return nil;
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
    BOOL userInterfaceHidden = self.srg_letterbox_parentView ? self.srg_letterbox_parentView.userInterfaceHidden : YES;
    [self updateLayoutForUserInterfaceHidden:userInterfaceHidden];
}

#pragma mark Subclassing hooks

- (void)didAttach
{}

- (void)reloadData
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
