//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MultiPlayerViewController : UIViewController <SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate>

- (instancetype)initWithURN:(nullable SRGMediaURN *)URN URN1:(nullable SRGMediaURN *)URN1 URN2:(nullable SRGMediaURN *)URN2 userInterfaceAlwaysHidden:(BOOL)userInterfaceAlwaysHidden;

@end

@interface MultiPlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
