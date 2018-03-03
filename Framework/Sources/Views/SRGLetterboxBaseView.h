//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxBaseView : UIView

- (void)updateForContentSizeCategory NS_REQUIRES_SUPER;
- (void)updateForAccessibility NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
