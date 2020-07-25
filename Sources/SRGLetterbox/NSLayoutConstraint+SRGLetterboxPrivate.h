//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSLayoutConstraint (SRGLetterboxPrivate)

/**
 *  Return the receiver with an adjusted priority.
 */
- (NSLayoutConstraint *)srgletterbox_withPriority:(UILayoutPriority)priority;

@end

NS_ASSUME_NONNULL_END
