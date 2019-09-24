//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
__attribute__((annotate("returns_localized_nsstring")))
OBJC_EXPORT NSString *LetterboxDemoNonLocalizedString(NSString *string);

/**
 *  Return the recommended resource name for the main resource (xib, storyboard) associated with a class.
 */
OBJC_EXPORT NSString *LetterboxDemoResourceNameForUIClass(Class cls);

NS_ASSUME_NONNULL_END
