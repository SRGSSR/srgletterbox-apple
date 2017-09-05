//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxView (Private)

/*
 *  Displayed error, if the error layer is displayed
 */
- (nullable NSError *)error;

/*
 *  Boolean return if the availabililty view is displayed or not
 */
- (BOOL)isDislayingAvailabilityView;

@end

NS_ASSUME_NONNULL_END
