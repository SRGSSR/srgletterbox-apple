//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Letterbox error constants. More information is available from the `userInfo` associated with these errors.
 */
typedef NS_ENUM(NSInteger, SRGLetterboxErrorCode) {
    /**
     *  The data or object was not found (available as underlying error).
     */
    SRGLetterboxErrorCodeNotFound,
    /**
     *  A network error has been encountered (available as underlying error).
     */
    SRGLetterboxErrorCodeNetwork,
    /**
     *  The media cannot be played for some reason (available as underlying error).
     */
    SRGLetterboxErrorCodeNotPlayable,
    /**
     *  The media is blocked. The reason itself can be retrieved under the `SRGLetterboxBlockingReasonKey`.
     */
    SRGLetterboxErrorCodeBlocked,
    /**
     *  The media is not available for playback. The reason itself can be retrieved under the `SRGLetterboxBlockingReasonKey` and `SRGLetterboxTimeAvailabilityKey`.
     */
    SRGLetterboxErrorCodeNotAvailable
};

/**
 *  Common domain for data provider errors
 */
OBJC_EXPORT NSString * const SRGLetterboxErrorDomain;

/**
 *  User info dictionary keys.
 */
OBJC_EXPORT NSString * const SRGLetterboxBlockingReasonKey;                // Key to an `NSNumber` wrapping an `SRGBlockingReason`, providing the blocking reason information.
OBJC_EXPORT NSString * const SRGLetterboxTimeAvailabilityKey;              // Key to an `NSNumber` wrapping an `SRGTimeAvailability`, providing the time availability information.

NS_ASSUME_NONNULL_END
