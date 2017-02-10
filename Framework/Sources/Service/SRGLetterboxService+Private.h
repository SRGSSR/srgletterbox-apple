//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxService.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when the service settings have been updated.
 */
OBJC_EXTERN NSString * const SRGLetterboxServiceSettingsDidChangeNotification;

@interface SRGLetterboxService (Private)

/**
 *  Stop picture in picture. If `restoreUserInterface` is set to `NO`, the restoration delegate methods will not be called
 */
- (void)stopPictureInPictureRestoreUserInterface:(BOOL)restoreUserInterface;

@end

NS_ASSUME_NONNULL_END
