//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Override behaviors for interfaces
 */
typedef NS_ENUM(NSInteger, SRGLetterboxViewBehavior) {
    /**
     *  Normal behavior.
     */
    SRGLetterboxViewBehaviorNormal = 0,
    /**
     *  Interface forced to be visible.
     */
    SRGLetterboxViewBehaviorForcedVisible,
    /**
     *  Interface forced to be hidden.
     */
    SRGLetterboxViewBehaviorForcedHidden
};

/**
 *  Return error conditions for a controller, from the point of view of a Letterbox view.
 */
OBJC_EXPORT NSError *SRGLetterboxViewErrorForController(SRGLetterboxController *controller);

/**
 *  Return the timeline height of the given view.
 */
OBJC_EXPORT CGFloat SRGLetterboxViewTimelineHeight(SRGLetterboxView *view, BOOL userInterfaceHidden);

/**
 *  Return `YES` iff the view is loading content.
 */
OBJC_EXPORT BOOL SRGLetterboxViewIsLoading(SRGLetterboxView *view);

@interface SRGLetterboxView (Private)

/*
 *  User interface behavior.
 */
- (SRGLetterboxViewBehavior)userInterfaceBehavior;

@end

NS_ASSUME_NONNULL_END
