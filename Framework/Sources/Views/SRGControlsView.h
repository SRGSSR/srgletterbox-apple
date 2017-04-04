//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@class SRGControlsView;

/**
 *  Controls view delegate protocol.
 */
@protocol SRGControlsViewDelegate <NSObject>

/**
 *  Called when the view did layout its subviews.
 */
- (void)controlsViewDidLayoutSubviews:(SRGControlsView *)controlsView;

@end

/**
 *  Internal view class for controls layout.
 */
@interface SRGControlsView : UIView

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) id<SRGControlsViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

