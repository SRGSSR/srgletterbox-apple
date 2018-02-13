//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Button displaying and animating remaining time as a circle progress bar.
 */
@interface SRGRemainingTimeButton : UIButton

/**
 *  Set progress, and the total duration required to move from 0 to 1.
 */
- (void)setProgress:(float)progress withDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
