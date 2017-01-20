//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxView;

@protocol SRGLetterboxViewDelegate <NSObject>

@optional
- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView;

@end

@interface SRGLetterboxView : UIView <SRGAirplayViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet id<SRGLetterboxViewDelegate> delegate;

- (void)animateAlongsideUserInterfaceWithAnimations:(nullable void (^)(BOOL hidden))animations completion:(nullable void (^)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
