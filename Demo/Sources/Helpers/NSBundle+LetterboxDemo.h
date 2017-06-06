//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return an accessibility-oriented localized string from the main bundle.
 */
#define SRGLetterboxDemoAccessibilityLocalizedString(key, comment) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:@"Accessibility"]

NS_ASSUME_NONNULL_END
