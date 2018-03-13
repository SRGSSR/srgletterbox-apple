//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A simple notification banner.
 */
IB_DESIGNABLE
@interface SRGNotificationView : SRGLetterboxBaseView

/**
 *  Update the notification for the specified message. Fits the view vertically and return the recommended height required
 *  for proper display.
 */
- (CGFloat)updateLayoutWithMessage:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
