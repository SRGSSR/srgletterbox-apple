//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (LetterboxDemo)

/**
 *  The top view controller displayed by the window.
 */
@property (nonatomic, readonly, nullable) UIViewController *letterbox_demo_topViewController;

/**
 *  Globally trigger a focus update. The focus engine determines which view should be focused in the entire top
 *  view controller hierarchy.
 */
- (void)letterbox_demo_updateFocus API_AVAILABLE(tvos(9.0)) API_UNAVAILABLE(ios);

@end

NS_ASSUME_NONNULL_END
