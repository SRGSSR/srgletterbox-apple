//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSLayoutConstraint+SRGLetterbox.h"

@implementation NSLayoutConstraint (SRGLetterbox)

- (NSLayoutConstraint *)srg_replacementConstraintWithMultiplier:(CGFloat)multiplier
{
    return [self srg_replacementConstraintWithMultiplier:multiplier constant:self.constant];
}

- (NSLayoutConstraint *)srg_replacementConstraintWithMultiplier:(CGFloat)multiplier constant:(CGFloat)constant
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.firstItem
                                                                  attribute:self.firstAttribute
                                                                  relatedBy:self.relation
                                                                     toItem:self.secondItem
                                                                  attribute:self.secondAttribute
                                                                 multiplier:multiplier
                                                                   constant:constant];
    constraint.priority = self.priority;
    
    [NSLayoutConstraint deactivateConstraints:@[ self ]];
    [NSLayoutConstraint activateConstraints:@[ constraint ]];
    
    return constraint;
}

@end
