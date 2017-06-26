//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  View associated with accessibility (mostly for display).
 */
@interface SRGAccessibilityView : UIView

@property (nonatomic, weak, nullable) IBOutlet SRGLetterboxView *letterboxView;

@end

NS_ASSUME_NONNULL_END
