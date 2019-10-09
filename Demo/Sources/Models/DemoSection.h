//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoSection : NSObject

@property(class, nonatomic, readonly) NSArray<DemoSection *> *homeSections;

@property (nonatomic, readonly, copy) NSString *headerTitle;
@property (nonatomic, readonly, copy) NSString *footerTitle;

@end

NS_ASSUME_NONNULL_END
