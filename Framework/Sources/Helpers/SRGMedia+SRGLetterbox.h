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
     *  Soon available content
     */
    SRGMediaAvailabilitySoon,
    /**
     *  Available content
     */
    SRGMediaAvailabilityAvailable,
    /**
     *  Expired available content
     */
    SRGMediaAvailabilityExpired
};

@interface SRGMedia (Letterbox)

@property (nonatomic, readonly) SRGMediaAvailability letterbox_availability;
@property (nonatomic, readonly, getter=letterbox_isToday) BOOL letterbox_today;

@end

NS_ASSUME_NONNULL_END
