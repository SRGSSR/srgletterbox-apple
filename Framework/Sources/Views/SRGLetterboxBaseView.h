//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

@class SRGLetterboxView;

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxBaseView : UIView

/**
 *  Return the Letterbox view context for the receiver.
 */
@property (nonatomic, readonly, nullable) SRGLetterboxView *contextView;

- (void)contentSizeCategoryDidChange NS_REQUIRES_SUPER;
- (void)voiceOverStatusDidChange NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
