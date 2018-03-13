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
 *  Concrete `SRGLetterboxControllerView` subclasses are created and used exactly like `SRGLetterboxBaseView` subclasses:
 *    - Create a new subclass, importing `SRGLetterboxControllerView.h` from its header file.
 *    - In the `.m` implementation file, import the `SRGLetterboxControllerView+Subclassing.h` header meant for subclass
 *      implementation.
 *    - Add an associated nib file bearing the same name as your class.
 *    - Add a simple `UIView` to your nib as first object, and set the File's owner type to your class. Bind any
 *      outlets to the File's owner.
 *    - Implement the various hook methods if required.
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

NS_ASSUME_NONNULL_END
