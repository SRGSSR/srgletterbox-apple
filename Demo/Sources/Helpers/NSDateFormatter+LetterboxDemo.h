//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (LetterboxDemo)

/**
 *  Relative date and time formatting, i.e. displays today / yesterday / tomorrow / ... for dates near today.
 *
 * @discussion Use `LetterboxDemoAccessibilityRelativeDateAndTimeFromDate` for accessibility-oriented formatting.
 */
@property (class, nonatomic, readonly) NSDateFormatter *letterbox_demo_relativeDateAndTimeFormatter;

@end

NS_ASSUME_NONNULL_END
