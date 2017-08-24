//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (SRGLetterbox)

/**
 *  Same as `-srg_relativeDateAndTimeFormatter` but for accessibility
 */
+ (NSDateFormatter *)srg_relativeDateAndTimeAccessibilityFormatter;

@end

NS_ASSUME_NONNULL_END
