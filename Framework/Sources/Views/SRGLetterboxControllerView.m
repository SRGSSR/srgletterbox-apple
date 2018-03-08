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
    
    [self didUpdateController];
    [self reloadData];
    [self updateLayoutForUserInterfaceHidden:self.parentView.userInterfaceHidden];
}

- (SRGLetterboxView *)parentView
{
    UIView *parentView = self.superview;
    while (parentView) {
        if ([parentView isKindOfClass:[SRGLetterboxView class]]) {
            return parentView;
        }
    }
    return nil;
}

#pragma mark Subclassing hooks

- (void)reloadData
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
