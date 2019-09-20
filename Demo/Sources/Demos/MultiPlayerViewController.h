//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__TVOS_PROHIBITED
@interface MultiPlayerViewController : UIViewController <SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate>

- (instancetype)initWithURN:(nullable NSString *)URN URN1:(nullable NSString *)URN1 URN2:(nullable NSString *)URN2 userInterfaceAlwaysHidden:(BOOL)userInterfaceAlwaysHidden;

@end

@interface MultiPlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
