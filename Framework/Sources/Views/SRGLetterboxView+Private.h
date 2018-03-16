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

@interface SRGLetterboxView (Private)

/**
 *  Return error information attached to the view.
 */
@property (nonatomic, readonly, nullable) NSError *error;

/*
 *  User interface behavior.
 */
@property (nonatomic, readonly) SRGLetterboxViewBehavior userInterfaceBehavior;

/**
 *  Return `YES` iff minimal user interface elements (full sceen button at the moment) are displayed. This is usually
 *  the case when the player is in a state where controls are hidden, but minimal user interface elements should
 *  remain reachable.
 */
@property (nonatomic, readonly, getter=isMinimal) BOOL minimal;

@end

NS_ASSUME_NONNULL_END
