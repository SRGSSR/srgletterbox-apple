//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMedia+SRGLetterbox.h"

@implementation SRGMedia (Letterbox)

- (SRGMediaAvailability)letterbox_availability
{
    SRGMediaAvailability availability = SRGMediaAvailabilityNone;
    
    if (self.contentType == SRGContentTypeLivestream) {
        availability = SRGMediaAvailabilityAvailable;
    }
    else {
        NSDate *startDate = nil;
        NSDate *endDate = nil;
        
        if (self.contentType == SRGContentTypeScheduledLivestream) {
            startDate = self.startDate ?: self.date;
            endDate = self.endDate ?: [self.date dateByAddingTimeInterval:self.duration / 1000.];
        }
        else {
            startDate = (self.blockingReason == SRGBlockingReasonStartDate) ? self.startDate : nil;
            endDate = (self.blockingReason == SRGBlockingReasonEndDate) ? self.endDate : nil;
        }
        
        NSDate *nowDate = NSDate.date;
        if (startDate && [nowDate compare:startDate] == NSOrderedAscending) {
            availability = SRGMediaAvailabilitySoon;
        }
        else if (endDate && [endDate compare:nowDate] == NSOrderedAscending) {
            availability = SRGMediaAvailabilityExpired;
        }
        else {
            availability = SRGMediaAvailabilityAvailable;
        }
    }
    return availability;
}

- (BOOL)letterbox_isToday
{
    return [[NSCalendar currentCalendar] isDateInToday:self.date];
}

@end
