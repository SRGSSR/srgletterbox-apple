//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSDateFormatter+LetterboxDemo.h"

@implementation NSDateFormatter (LetterboxDemo)

+ (NSDateFormatter *)letterbox_demo_relativeDateAndTimeFormatter
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
