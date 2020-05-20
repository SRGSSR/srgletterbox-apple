//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (SRGLetterbox)

/**
 *  Absolute time formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *srgletterbox_timeFormatter;

/**
 *  Relative date and time formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today.
 */
@property (class, nonatomic, readonly) NSDateFormatter *srgletterbox_relativeDateAndTimeFormatter;

@end

NS_ASSUME_NONNULL_END
