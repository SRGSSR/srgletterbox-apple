//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import "SRGLetterboxView.h"

@interface SRGLetterboxControllerView ()

@property (nonatomic, readonly) SRGLetterboxView *parentView;

@end

@implementation SRGLetterboxControllerView

#pragma mark Getters and setters

- (void)setController:(SRGLetterboxController *)controller
{
    _controller = controller;
    
    [self didAttach];
    [self reloadData];
    [self updateLayoutForUserInterfaceHidden:self.parentView.userInterfaceHidden];
}

- (SRGLetterboxView *)parentView
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

#pragma mark Subclassing hooks

- (void)didAttach
{
    
}

- (void)reloadData
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
