//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"
#import "SRGLetterboxBaseView.h"
#import "SRGLetterboxView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxControllerView : SRGLetterboxBaseView

@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

- (void)updateForController:(nullable SRGLetterboxController *)controller NS_REQUIRES_SUPER;
- (void)updateLayoutForController:(nullable SRGLetterboxController *)controller view:(SRGLetterboxView *)view userInterfaceHidden:(BOOL)userInterfaceHidden  NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
