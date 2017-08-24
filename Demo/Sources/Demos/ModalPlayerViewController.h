//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModalPlayerViewController : UIViewController <SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate>

- (instancetype)initWithURN:(nullable SRGMediaURN *)URN chaptersOnly:(BOOL)chaptersOnly serviceURL:(nullable NSURL *)serviceURL;

@property (nonatomic) NSTimeInterval streamAvailabilityCheckInterval;

@end

@interface ModalPlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
