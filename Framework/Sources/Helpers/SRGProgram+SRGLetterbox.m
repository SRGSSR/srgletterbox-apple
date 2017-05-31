//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgram+SRGLetterbox.h"

@implementation SRGProgram (SRGLetterbox)

- (BOOL)srgletterbox_containsDate:(NSDate *)date
{
    return [self.startDate compare:date] != NSOrderedDescending && [date compare:self.endDate] != NSOrderedDescending;
}

@end
