//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"
#import "SRGLetterboxView.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Accessibility player placeholder view.
 */
API_UNAVAILABLE(tvos)
@interface SRGAccessibilityView : SRGLetterboxBaseView

/**
 *  The view which which the accessibility frame must correspond to. If none specified, the receiver frame is
 *  used.
 */
@property (nonatomic, weak) IBOutlet UIView *accessibilityFrameView;

@end

NS_ASSUME_NONNULL_END
