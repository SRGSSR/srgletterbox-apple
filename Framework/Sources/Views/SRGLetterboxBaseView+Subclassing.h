//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"
#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  `SRGLetterboxBaseView` is an abstract base class for Letterbox-related views. It provides:
 *    - Automatic instantiation from a nib file bearing the class name.
 *    - Built-in support for content size category and VoiceOver changes.
 *    - Transaction-oriented layout management, ensuring that layout changes are made in the context of the parent
 *      Letterbox view.
 *
 *  Concrete subclasses of `SRGLetterboxBaseView` are especially suited as overlays contained within a Letterbox
 *  view, as they are able to automatically find which parent view context they belong to.
 *
 *  To create your own concrete `SRGLetterboxBaseView` subclass:
 *    - Create a new subclass, importing SRGLetterboxBaseView+Subclassing.h
 *    - Add an associated nib file bearing the same name as your class.
 *    - Add a simple `UIView` to your nib as first object, and set the File's owner type to your class. Bind any
 *      outlets to the File's owner.
 *    - Implement the various hook methods if required.
 *
 *  To use your custom view, either instantiate it somewhere in your code, or simply add a `UIView` in one of
 *  your nibs or storyboards (with no subviews), setting its class to your custom class.
 */
@interface SRGLetterboxBaseView (Subclassing)

/**
 *  Return the Letterbox view context for the receiver, if any.
 *
 *  @discussion The context of an `SRGLetterboxView` is the view itself.
 */
@property (nonatomic, readonly, nullable) SRGLetterboxView *contextView;

/**
 *  Method called when the content size category changes. Subclasses can e.g. implement this method if needed to adjust
 *  font sizes accordingly.
 */
- (void)contentSizeCategoryDidChange NS_REQUIRES_SUPER;

/**
 *  Method called when the VoiceOver status change. Subclasses can e.g. implement this method if needed for special
 *  adjustments needed when VoiceOver is active.s
 */
- (void)voiceOverStatusDidChange NS_REQUIRES_SUPER;

/**
 *  Method called when the parent Letterbox context view is required to perform a layout update.
 *
 *  @discussion Never call this method directly. If your subclass needs to ask for a layout, call `-setNeedsLayoutAnimated:`
 *              instead.
 */
- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden NS_REQUIRES_SUPER;

/**
 *  Call to trigger a layout update.
 */
- (void)setNeedsLayoutAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
