//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"
#import "SRGLetterboxController.h"

NS_ASSUME_NONNULL_BEGIN

// TODO: Hide everything in a subclassing category, except the controller property. Probably import
//       SRGLetterboxView.h from the private header.

@interface SRGLetterboxControllerView : SRGLetterboxBaseView

/**
 *  The controller bound to the view. The controller can be changed at any time, the view will automatically be updated
 *  accordingly.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGLetterboxController *controller;

- (void)willDetachFromController NS_REQUIRES_SUPER;
- (void)didDetachFromController NS_REQUIRES_SUPER;

- (void)willAttachToController NS_REQUIRES_SUPER;
- (void)didAttachToController NS_REQUIRES_SUPER;

- (void)reloadData NS_REQUIRES_SUPER;

// Document: Update INTERNAL constraint / subview visibility (not constraints on self, e.g. not its own height or its own alpha or hidden
// property). External constraints are the responsibility of the superview.
- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden NS_REQUIRES_SUPER;

@end

@interface UIView (SRGLetterboxControllerView)

- (void)srg_recursivelyReloadData;
- (void)srg_recursivelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden;

@end

NS_ASSUME_NONNULL_END
