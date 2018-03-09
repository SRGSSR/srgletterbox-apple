//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Control wrapper view helps a control to have margin constraints in the control stack view.
 */
@interface SRGControlWrapperView : UIView

/**
 *  When set to `YES`, force the view to be hidden / display like the first subview.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isObservingFirstSubviewHidden) IBInspectable BOOL observingFirstSubviewHidden;

/**
 *  When set to `YES`, force the view to be always hidden, even if subviews aren't hidden.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isAlwaysHidden) IBInspectable BOOL alwaysHidden;

@end
