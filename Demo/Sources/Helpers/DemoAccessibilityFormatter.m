//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoAccessibilityFormatter.h"

#import "NSBundle+LetterboxDemo.h"

@import SRGDataProviderModel;

NSString *LetterboxDemoAccessibilityShortTimeFromDate(NSDate *date)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleSpellOut;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorNone;
    });
    
    NSDateComponents *components = [NSCalendar.currentCalendar components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                 fromDate:date];
    return [s_dateComponentsFormatter stringFromDateComponents:components];
}

NSString *LetterboxDemoAccessibilityRelativeDateAndTimeFromDate(NSDate *date)
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterLongStyle;
        s_dateFormatter.timeStyle = NSDateFormatterNoStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    NSString *dateString = [s_dateFormatter stringFromDate:date];
    
    NSString *timeString = LetterboxDemoAccessibilityShortTimeFromDate(date);
    return [NSString stringWithFormat:LetterboxDemoAccessibilityLocalizedString(@"%1$@ at %2$@", @"Date at time label to spell a date and time value."), dateString, timeString];
}
