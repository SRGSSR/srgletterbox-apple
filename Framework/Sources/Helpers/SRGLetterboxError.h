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
     *  The data or object was not found.
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
     *  The media is blocked.
     */
    SRGLetterboxErrorCodeBlocked
};

/**
 *  Common domain for data provider errors
 */
OBJC_EXPORT NSString * const SRGLetterboxErrorDomain;

NS_ASSUME_NONNULL_END
