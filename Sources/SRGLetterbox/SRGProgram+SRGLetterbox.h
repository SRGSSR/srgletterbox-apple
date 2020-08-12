//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgram (SRGLetterbox)

/**
 *  Returns `YES` iff the program contains the specified date.
 */
- (BOOL)srgletterbox_containsDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
