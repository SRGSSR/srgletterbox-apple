//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Control wrapper view helps a control to have margin constraints in the control stack view.
 */
@interface SRGControlWrapperView : UIView

/**
 *  When set to `YES`, force the view to be hidden / display like the first subview.
 *
 *  Default value is `NO`.
 *
 *  @discussion When set to `YES`, the view is shown or hidden by having its `hidden` property automatically adjusted.
 *              Attempting to manually alter this property in this case leads to undefined behavior. You can still
 *              force the view to always be hidden by setting its `alwaysHidden` property to `YES` if needed.
 */
@property (nonatomic, getter=isMatchingFirstSubviewHidden) IBInspectable BOOL matchingFirstSubviewHidden;

/**
 *  When set to `YES`, force the view to be always hidden, even if subviews aren't hidden.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isAlwaysHidden) IBInspectable BOOL alwaysHidden;

@end

NS_ASSUME_NONNULL_END
