//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSLayoutConstraint (SRGLetterbox)

/**
 *  Replace a constraint with an equivalent one having the specified multiplier. Returns the new constraint.
 */
- (NSLayoutConstraint *)srg_replacementConstraintWithMultiplier:(CGFloat)multiplier;

/**
 *  Replace a constraint with an equivalent one having the specified multiplier and constant. Returns the new
 *  constraint.
 */
- (NSLayoutConstraint *)srg_replacementConstraintWithMultiplier:(CGFloat)multiplier constant:(CGFloat)constant;

@end

NS_ASSUME_NONNULL_END
