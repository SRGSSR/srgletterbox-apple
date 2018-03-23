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
 *  A simple view displaying a remaining time (in seconds).
 */
IB_DESIGNABLE
@interface SRGCountdownView : SRGLetterboxBaseView

/**
 *  The remaining time to be displayed (in seconds).
 */
@property (nonatomic) NSTimeInterval remainingTimeInterval;

@end

NS_ASSUME_NONNULL_END
