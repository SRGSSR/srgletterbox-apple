//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateComponentsFormatter (SRGLetterbox)

/**
 *  Standard date components formatter with days, hours, minutes and seconds.
 */
+ (NSDateComponentsFormatter *)srg_longDateComponentsFormatter;

/**
 *  Standard date components formatter with hours, minutes and seconds.
 */
+ (NSDateComponentsFormatter *)srg_mediumDateComponentsFormatter;

/**
 *  Standard date components formatter with minutes and seconds.
 */
+ (NSDateComponentsFormatter *)srg_shortDateComponentsFormatter;

@end

NS_ASSUME_NONNULL_END
