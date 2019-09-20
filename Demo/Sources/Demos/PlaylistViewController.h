//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__TVOS_PROHIBITED
@interface PlaylistViewController : UIViewController <SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate>

- (instancetype)initWithMedias:(nullable NSArray<SRGMedia *> *)medias sourceUid:(nullable NSString *)sourceUid;

@end

@interface PlaylistViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
