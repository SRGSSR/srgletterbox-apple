//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Convenience macro for localized strings associated with the framework.
 */
#define SRGLetterboxLocalizedString(key, comment) [SWIFTPM_MODULE_BUNDLE localizedStringForKey:(key) value:@"" table:nil]

/**
 *  Return an accessibility-oriented localized string associated with the framework.
 */
#define SRGLetterboxAccessibilityLocalizedString(key, comment) [SWIFTPM_MODULE_BUNDLE localizedStringForKey:(key) value:@"" table:@"Accessibility"]

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
__attribute__((annotate("returns_localized_nsstring")))
OBJC_EXPORT NSString *SRGLetterboxNonLocalizedString(NSString *string);

NS_ASSUME_NONNULL_END
