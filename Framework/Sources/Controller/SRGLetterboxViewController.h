//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxViewController : SRGMediaPlayerViewController

/**
 *  Instantiate a view controller whose playback is managed by the specified controller. If none is provided a default
 *  one will be automatically created.
 */
- (instancetype)initWithLetterboxController:(nullable SRGLetterboxController *)letterboxController;

/**
 *  The controller used for playback.
 */
@property (nonatomic, readonly) SRGLetterboxController *letterboxController;

@end

NS_ASSUME_NONNULL_END
