//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxService.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxService (Private)

/**
 *  The singleton instance
 */
+ (SRGLetterboxService *)sharedService;

/**
 *  Picture in picture delegate. Picture in picture won't be available if not set
 *
 *  @discussion The delegate is retained
 */
@property (nonatomic, nullable) id<SRGLetterboxPictureInPictureDelegate> pictureInPictureDelegate;

/**
 *  Stop picture in picture. If `restoreUserInterface` is set to NO, the restoration delegate methods will not be called
 */
- (void)stopPictureInPictureRestoreUserInterface:(BOOL)restoreUserInterface;

@end

NS_ASSUME_NONNULL_END
