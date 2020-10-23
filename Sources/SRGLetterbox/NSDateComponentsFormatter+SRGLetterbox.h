//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSDateComponentsFormatter (SRGLetterbox)

/**
 *  Standard date components formatter with days, hours, minutes and seconds.
 */
@property (class, nonatomic, readonly) NSDateComponentsFormatter *srg_longDateComponentsFormatter;

/**
 *  Standard date components formatter with hours, minutes and seconds.
 */
@property (class, nonatomic, readonly) NSDateComponentsFormatter *srg_mediumDateComponentsFormatter;

/**
 *  Standard date components formatter with minutes and seconds.
 */
@property (class, nonatomic, readonly) NSDateComponentsFormatter *srg_shortDateComponentsFormatter;

/**
 *  Date components formatter for accessibility purposes.
 */
@property (class, nonatomic, readonly) NSDateComponentsFormatter *srg_accessibilityDateComponentsFormatter;

@end

NS_ASSUME_NONNULL_END
