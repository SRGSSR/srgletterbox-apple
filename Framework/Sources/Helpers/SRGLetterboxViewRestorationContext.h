//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Stores an `SRGLetterboxView` context for restoration. A context must be provided with a name. Two contexts
 *  with the same name are considered equal.
 */
@interface SRGLetterboxViewRestorationContext : NSObject

/**
 *  Create a restoration context based on the properties of the specified view, and identified by the provided name.
 */
- (instancetype)initWithName:(NSString *)name;

/**
 *  Context properties.
 */
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isTogglable) BOOL togglable;

@end

NS_ASSUME_NONNULL_END
