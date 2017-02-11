//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Convenience macro for localized strings associated with the framework.
 */
#define SRGLetterboxLocalizedString(key, comment) [[NSBundle srg_letterboxBundle] localizedStringForKey:(key) value:@"" table:nil]

@interface NSBundle (SRGLetterbox)

/**
 *  The SRGLetterbox resource bundle.
 */
+ (NSBundle *)srg_letterboxBundle;

@end

NS_ASSUME_NONNULL_END
