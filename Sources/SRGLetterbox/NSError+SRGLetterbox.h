//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (SRGLetterbox)

/**
 *  Return the first error related to a network issue, from the error to underlying errors.
 */
@property (nonatomic, readonly, nullable) NSError *srg_letterboxNetworkError;

@end

NS_ASSUME_NONNULL_END
