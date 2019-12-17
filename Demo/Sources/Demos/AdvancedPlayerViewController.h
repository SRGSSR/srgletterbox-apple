//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_UNAVAILABLE(tvos)
@interface AdvancedPlayerViewController : UIViewController <SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>

- (instancetype)initWithURN:(nullable NSString *)URN serviceURL:(nullable NSURL *)serviceURL;

@property (nonatomic) NSTimeInterval updateInterval;

@end

@interface AdvancedPlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
