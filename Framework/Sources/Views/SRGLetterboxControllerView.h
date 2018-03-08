//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"
#import "SRGLetterboxBaseView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxControllerView : SRGLetterboxBaseView

@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

- (void)didAttach NS_REQUIRES_SUPER;

- (void)reloadData NS_REQUIRES_SUPER;

// Document: Update INTERNAL constraint / subview visibility (not constraints on self, e.g. not its own height or its own alpha or hidden
// property). External constraints are the responsibility of the superview.
- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
