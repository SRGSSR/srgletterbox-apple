//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSURL *LetterboxDemoMMFServiceURL(void);

OBJC_EXPORT NSURL *LetterboxDemoServiceURLForKey(NSString *key);
OBJC_EXPORT NSString *LetterboxDemoServiceNameForKey(NSString *key);
OBJC_EXPORT NSString *LetterboxDemoServiceNameForURL(NSURL *URL);

@interface ServerSettings : NSObject

@property (class, nonatomic, readonly) NSArray<ServerSettings *> *serverSettings;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL *URL;

@end

@interface ServerSettings (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
