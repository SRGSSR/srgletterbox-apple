//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a relative date and time, i.e. returns today / yesterday / tomorrow / ... for dates near today, in a human
 *  readable way suited for accessibilty.
 *
 *  @discussion Similar to `+[NSDateFormatter letterbox_demo_relativeDateAndTimeFormatter]`, but for accessibility purposes.
 */
OBJC_EXPORT NSString *LetterboxDemoAccessibilityRelativeDateAndTimeFromDate(NSDate *date);

NS_ASSUME_NONNULL_END
