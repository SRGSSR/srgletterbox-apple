//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgram (SRGLetterbox)

/**
 *  Returns `YES` iff the program is on air on the specified date.
 */
- (BOOL)containsDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
