//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlButton.h"
#import "UIImage+SRGLetterbox.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A control button to display a button with a label underneath.
 */
@interface SRGLabeledControlButton : SRGControlButton

/**
 *  The image set associated with the button.
 */
@property (nonatomic) SRGImageSet imageSet;

@end

NS_ASSUME_NONNULL_END
