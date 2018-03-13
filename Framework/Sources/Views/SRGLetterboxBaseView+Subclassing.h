//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"

#import "SRGLetterboxView+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxBaseView (Subclassing)

/**
 *  Return the Letterbox view context for the receiver.
 */
@property (nonatomic, readonly, nullable) SRGLetterboxView *contextView;

- (void)contentSizeCategoryDidChange NS_REQUIRES_SUPER;
- (void)voiceOverStatusDidChange NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
