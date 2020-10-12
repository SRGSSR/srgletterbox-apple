//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (SRGLetterbox)

/**
 *  Return `YES` iff the error or underlying errors are related to a not connected to internet error code.
 */
@property (nonatomic, readonly) BOOL srg_letterbox_isNotConnectedToInternet;

@end

NS_ASSUME_NONNULL_END
