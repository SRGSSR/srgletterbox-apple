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
@interface SRGCountdownView : SRGLetterboxBaseView

/**
 *  Instantiate a countdown targeting the target date.
 */
- (instancetype)initWithTargetDate:(NSDate *)targetDate frame:(CGRect)frame;

/**
 *  The target date.
 */
@property (nonatomic, readonly) NSDate *targetDate;

@end

NS_ASSUME_NONNULL_END
