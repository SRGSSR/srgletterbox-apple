//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

@interface SRGLetterboxControllerView ()

@property (nonatomic, weak) SRGLetterboxController *controller;
@property (nonatomic, weak) SRGLetterboxView *view;

@end

@implementation SRGLetterboxControllerView

#pragma mark Binding

- (void)setController:(SRGLetterboxController *)controller view:(SRGLetterboxView *)view
{
    self.controller = controller;
    self.view = view;
}

#pragma mark Subclassing hooks

- (void)reloadData
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

@end
