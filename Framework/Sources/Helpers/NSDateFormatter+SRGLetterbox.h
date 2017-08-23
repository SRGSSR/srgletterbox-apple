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
 *  Use only relative date formatting, i.e. displays today / yesterday for dates near today
 */
+ (NSDateFormatter *)srg_relativeDateFormatter;

/**
 *  Use only short time formatting
 */
+ (NSDateFormatter *)srg_relativeTimeFormatter;

/**
 *  Same as `-srg_relativeDateAndTimeFormatter` but for accessibility
 */
+ (NSDateFormatter *)srg_relativeDateAndTimeAccessibilityFormatter;

/**
 *  Same as `-srg_relativeDateAndTimeFormatter` but for accessibility
 */
+ (NSDateFormatter *)srg_relativeDateAccessibilityFormatter;

/**
 *  Same as `-srg_relativeDateAndTimeFormatter` but for accessibility
 */
+ (NSDateFormatter *)srg_relativeTimeAccessibilityFormatter;

@end

NS_ASSUME_NONNULL_END
