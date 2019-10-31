//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Media.h"

NS_ASSUME_NONNULL_BEGIN

@interface DemoSection : NSObject

@property (class, nonatomic, readonly) NSArray<DemoSection *> *sections;

@property (nonatomic, readonly, copy, nullable) NSString *name;
@property (nonatomic, readonly, copy, nullable) NSString *summary;
@property (nonatomic, readonly) NSArray<Media *> *medias;

@end

NS_ASSUME_NONNULL_END
