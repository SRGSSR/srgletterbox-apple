//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxBaseView : UIView

@property (nonatomic, weak, nullable) SRGLetterboxController *controller;

- (void)updateFonts;
- (void)updateAccessibility;

- (void)updateForController:(nullable SRGLetterboxController *)controller;

@end

NS_ASSUME_NONNULL_END
