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

- (void)controlsViewDidLayoutSubviews:(SRGControlsView *)controlsView;

@end

/**
 *  This simple view has just a delegate to forward layoutSubviews events. Control buttons aren't here.
 *
 *  @discussion See `SRGLetterboxView` to see all control buttons
 */

@interface SRGControlsView : UIView

/**
 *  View optional delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGControlsViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

