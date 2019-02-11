//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServerSettings : NSObject

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)URL;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL *URL;

@end

@interface ServerSettings (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
