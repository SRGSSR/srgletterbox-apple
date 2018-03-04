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

@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

// Only called if a controller was attached
- (void)willDetachFromController NS_REQUIRES_SUPER;
- (void)didAttachToController NS_REQUIRES_SUPER;


// TODO: -didUpdateMetatadata?
- (void)reloadData NS_REQUIRES_SUPER;

// Update INTERNAL constraint / subview visibility (not constraints on self, e.g. not its own height or its own alpha or hidden
// property). External constraints are the responsibility of the superview.

// TODO: -didUpdateLayout...?
- (void)updateLayoutForView:(SRGLetterboxView *)view userInterfaceHidden:(BOOL)userInterfaceHidden  NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
