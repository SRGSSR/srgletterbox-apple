//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (SRGLetterbox)

/**
 *  Return the first contained the error or underlying errors related to a network issue.
 */
@property (nonatomic, readonly, nullable) NSError *srg_letterboxNetworkError;

@end

NS_ASSUME_NONNULL_END
