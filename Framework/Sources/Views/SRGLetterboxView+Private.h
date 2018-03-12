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

- (void)updateLayoutAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
