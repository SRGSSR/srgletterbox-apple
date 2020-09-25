//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSLayoutConstraint+SRGLetterboxPrivate.h"

@implementation NSLayoutConstraint (SRGLetterboxPrivate)

- (NSLayoutConstraint *)srgletterbox_withPriority:(UILayoutPriority)priority
{
    self.priority = priority;
    return self;
}

@end
