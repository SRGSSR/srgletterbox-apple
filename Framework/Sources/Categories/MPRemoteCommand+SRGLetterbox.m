//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MPRemoteCommand+SRGLetterbox.h"

@implementation MPRemoteCommand (SRGLetterbox)

- (void)srg_addUniqueTarget:(id)target action:(SEL)action
{
    [self removeTarget:target];
    [self addTarget:target action:action];
}

@end
