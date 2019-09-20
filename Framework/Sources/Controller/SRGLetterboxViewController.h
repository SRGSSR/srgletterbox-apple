//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxViewController : UIViewController

/**
 *  Instantiate a view controller whose playback is managed by the specified controller. If none is provided a default
 *  one will be automatically created.
 */
- (instancetype)initWithController:(nullable SRGLetterboxController *)controller;

/**
 *  The controller used for playback.
 */
@property (nonatomic, readonly) SRGLetterboxController *controller;

@end

NS_ASSUME_NONNULL_END
