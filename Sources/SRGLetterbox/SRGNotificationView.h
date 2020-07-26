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
@interface SRGNotificationView : SRGLetterboxBaseView

/**
 *  Update the notification for the specified message. Return the recommended size required for proper display.
 */
- (CGSize)updateLayoutWithMessage:(nullable NSString *)message width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
