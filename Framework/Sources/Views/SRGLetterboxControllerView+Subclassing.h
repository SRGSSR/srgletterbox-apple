//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxControllerView.h"

#import "SRGLetterboxBaseView+Subclassing.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  `SRGLetterboxControllerView` is an abstract class for Letterbox views bound to a controller. In addition to features
 *  provided by `SRGLetterboxBaseView` (e.g. convenient instantiation via nib files), it provides various hooks common
 *  to all views synchronized with a controller. Three kinds of hooks are available:
 *    - Controller hooks, called when a controller is attached or detached, and in which subclasses can e.g. perform
 *      additional controller registrations and unregistrations.
 *    - Metadata and failure hooks, called when the controller updates its metadata or fails for some reason.
 *
 *  Concrete `SRGLetterboxControllerView` subclasses are created and used exactly like `SRGLetterboxBaseView` subclasses
 *  (@see `SRGLetterboxBaseView` documentation). When implementing them, however, use the various available hooks to
 *  ensure that your view appropriately responds to controller changes, metadata updates and layout requests.
 */
@interface SRGLetterboxControllerView (Subclassing)

/**
 *  Method called when the view is about to be detached from its controller.
 *
 *  @discussion Called only when a controller was attached, still available as `self.controller`.
 */
- (void)willDetachFromController NS_REQUIRES_SUPER;

/**
 *  Method called when the view has been detached from its controller.
 *
 *  @discussion Called only when a controller was attached. `self.controller` is `nil`.
 */
- (void)didDetachFromController NS_REQUIRES_SUPER;

/**
 *  Method called when the view is about to be attached to a new controller.
 *
 *  @discussion Called only when a new controller will be attached. `self.controller` is `nil`.
 */
- (void)willAttachToController NS_REQUIRES_SUPER;

/**
 *  Method called when the view has been attached to a new controller.
 *
 *  @discussion The new controller is available as `self.controller`.
 */
- (void)didAttachToController NS_REQUIRES_SUPER;

/**
 *  Method called when the attached controller updated the associated metadata.
 */
- (void)metadataDidChange NS_REQUIRES_SUPER;

/**
 *  Method called when the attached controller encountered a playback failure.
 */
- (void)playbackDidFail NS_REQUIRES_SUPER;

@end

// TODO: Hide in SRGLetterboxView.m
@interface UIView (SRGLetterboxControllerView)

- (void)srg_recursivelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden;

@end

NS_ASSUME_NONNULL_END
