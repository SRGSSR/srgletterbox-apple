//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import "SRGLetterboxBaseView+Subclassing.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxControllerView (Subclassing)

- (void)willDetachFromController NS_REQUIRES_SUPER;
- (void)didDetachFromController NS_REQUIRES_SUPER;

- (void)willAttachToController NS_REQUIRES_SUPER;
- (void)didAttachToController NS_REQUIRES_SUPER;

- (void)metadataDidChange NS_REQUIRES_SUPER;
- (void)playbackDidFail NS_REQUIRES_SUPER;

// Document: Update INTERNAL constraint / subview visibility (not constraints on self, e.g. not its own height or its own alpha or hidden
// property). External constraints are the responsibility of the superview.
// NEVER call directly. Is called by the parent Letterbox view to always ensure a consistent layout transactions are made.
// No assumption must be made about the order in which metadataDidChange and updateLayout are called
- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden NS_REQUIRES_SUPER;

@end

// TODO: Hide in SRGLetterboxView.m
@interface UIView (SRGLetterboxControllerView)

- (void)srg_recursivelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden;

@end

NS_ASSUME_NONNULL_END
