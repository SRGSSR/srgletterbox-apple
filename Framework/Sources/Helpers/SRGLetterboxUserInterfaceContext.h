//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Stores an `SRGLetterboxView` user interface context. A context must be provided with a identifier. Two contexts
 *  with the same identifier are considered equal.
 */
@interface SRGLetterboxUserInterfaceContext : NSObject

/**
 *  Create a context based on the properties of the specified view, and identified by the provided identifier.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier;

/**
 *  Context properties.
 */
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isTogglable) BOOL togglable;

@end

NS_ASSUME_NONNULL_END
