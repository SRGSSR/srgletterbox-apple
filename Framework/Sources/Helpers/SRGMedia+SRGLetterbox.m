//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMedia+SRGLetterbox.h"

@implementation SRGMedia (SRGLetterbox)

- (SRGMediaAvailability)srg_availability
{
    NSDate *nowDate = NSDate.date;
    if (self.startDate && [nowDate compare:self.startDate] == NSOrderedAscending) {
        return SRGMediaAvailabilityNotYet;
    }
    else if (self.endDate && [self.endDate compare:nowDate] == NSOrderedAscending) {
        return SRGMediaAvailabilityExpired;
    }
    else {
        return SRGMediaAvailabilityAvailable;
    }
}

@end
