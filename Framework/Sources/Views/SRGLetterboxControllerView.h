//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"
#import "SRGLetterboxBaseView.h"
#import "SRGLetterboxView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxControllerView : SRGLetterboxBaseView

- (void)setController:(nullable SRGLetterboxController *)controller view:(SRGLetterboxView *)view NS_REQUIRES_SUPER;

@property (nonatomic, readonly, weak, nullable) SRGLetterboxController *controller;
@property (nonatomic, readonly, weak, nullable) SRGLetterboxView *view;

// TODO: -didUpdateMetatadata?
- (void)reloadData NS_REQUIRES_SUPER;

// Update INTERNAL constraint / subview visibility (not constraints on self, e.g. not its own height or its own alpha or hidden
// property). External constraints are the responsibility of the superview.

// TODO: -didUpdateLayout...?
- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
