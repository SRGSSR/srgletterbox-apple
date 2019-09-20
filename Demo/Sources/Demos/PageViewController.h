//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__TVOS_PROHIBITED
@interface PageViewController : UIPageViewController <UIPageViewControllerDataSource>

- (instancetype)initWithURNs:(nullable NSArray<NSString *> *)URNs;

@end

NS_ASSUME_NONNULL_END
