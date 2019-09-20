//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__TVOS_PROHIBITED
@interface PlayerPageViewController : UIViewController

- (instancetype)initWithURN:(NSString *)URN;

@property (nonatomic, readonly, copy) NSString *URN;

@end

@interface PlayerPageViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
