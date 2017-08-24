//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (SRGLetterbox)

/**
 *  Use relative date and time formatting, i.e. displays today / yesterday for dates near today
 */
+ (NSDateFormatter *)srg_relativeDateAndTimeFormatter;

/**
 *  Same as `-srg_relativeDateAndTimeFormatter` but for accessibility
 */
+ (NSDateFormatter *)srg_relativeDateAndTimeAccessibilityFormatter;

@end

NS_ASSUME_NONNULL_END
