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
#define SRGLetterboxLocalizedString(key, comment) [NSBundle.srg_letterboxBundle localizedStringForKey:(key) value:@"" table:nil]

/**
 *  Return an accessibility-oriented localized string associated with the framework.
 */
#define SRGLetterboxAccessibilityLocalizedString(key, comment) [NSBundle.srg_letterboxBundle localizedStringForKey:(key) value:@"" table:@"Accessibility"]

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
__attribute__((annotate("returns_localized_nsstring")))
OBJC_EXPORT NSString *SRGLetterboxNonLocalizedString(NSString *string);

OBJC_EXPORT NSString *SRGLetterboxResourceNameForUIClass(Class cls);

@interface NSBundle (SRGLetterbox)

/**
 *  The SRGLetterbox resource bundle.
 */
@property (class, nonatomic, readonly) NSBundle *srg_letterboxBundle;

/**
 *  Return `YES` iff the application bundle corresponds to an AppStore or TestFlight release.
 */
@property (class, nonatomic, readonly) BOOL srg_letterbox_isProductionVersion;

@end

NS_ASSUME_NONNULL_END
