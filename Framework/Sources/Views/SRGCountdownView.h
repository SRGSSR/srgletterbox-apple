//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return date components corresponding to a given time interval since the current date.
 */
OBJC_EXPORT NSDateComponents *SRGDateComponentsForTimeIntervalSinceNow(NSTimeInterval timeInterval);

/**
 *  For time intervals greater or equivalent to `SRGCountdownViewDaysLimit` (in days), the countdown cannot
 *  display precise components because of layout space restrictions. In such cases the countdown displays the
 *  maximum value supported by its layout.
 */
OBJC_EXPORT NSInteger SRGCountdownViewDaysLimit;

/**
 *  A simple view displaying a remaining time (in seconds) as a fancy countdown.
 */
IB_DESIGNABLE
@interface SRGCountdownView : SRGLetterboxBaseView

/**
 *  The remaining time to be displayed (in seconds).
 */
@property (nonatomic) NSTimeInterval remainingTimeInterval;

@end

NS_ASSUME_NONNULL_END
