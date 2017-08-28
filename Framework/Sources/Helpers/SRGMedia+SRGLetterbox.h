//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Media availability.
 */
typedef NS_ENUM(NSInteger, SRGMediaAvailability) {
    /**
     *  Not specified.
     */
    SRGMediaAvailabilityNone = 0,
    /**
     *  The media is not available yet.
     */
    SRGMediaAvailabilityNotYet,
    /**
     *  The media is available.
     */
    SRGMediaAvailabilityAvailable,
    /**
     *  The media has expired and is not available anymore.
     */
    SRGMediaAvailabilityExpired
};

@interface SRGMedia (SRGLetterbox)

@property (nonatomic, readonly) SRGMediaAvailability srg_availability;

@end

NS_ASSUME_NONNULL_END
