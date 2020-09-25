//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSDateFormatter+SRGLetterbox.h"

@implementation NSDateFormatter (SRGLetterbox)

#pragma mark Class methods

+ (NSDateFormatter *)srgletterbox_timeFormatter
{
    static dispatch_once_t s_onceToken;
    static NSDateFormatter *s_dateFormatter;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.dateStyle = NSDateFormatterNoStyle;
        s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)srgletterbox_relativeDateAndTimeFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.dateStyle = NSDateFormatterShortStyle;
        s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    return s_dateFormatter;
}

@end
