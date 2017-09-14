//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  User interface behavior
 */
typedef NS_ENUM(NSInteger, SRGLetterboxViewUserInterfaceBehavior) {
    /**
     *  Normal behavior.
     */
    SRGLetterboxViewUserInterfaceBehaviorNormal = 0,
    /**
     *  User interface forced to be visible.
     */
    SRGLetterboxViewUserInterfaceBehaviorForcedVisible,
    /**
     *  User interface forced to be hidden.
     */
    SRGLetterboxViewUserInterfaceBehaviorForcedHidden
};

@interface SRGLetterboxView (Private)

/*
 *  User interface behavior.
 */
- (SRGLetterboxViewUserInterfaceBehavior)userInterfaceBehavior;

@end

NS_ASSUME_NONNULL_END
