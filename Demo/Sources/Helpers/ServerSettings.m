//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ServerSettings.h"

@interface ServerSettings ()

@property (nonatomic) NSString *name;
@property (nonatomic) NSURL *URL;
@property (nonatomic) NSDictionary<NSString *, NSString *> *globalHeaders;

@end

@implementation ServerSettings

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)URL globalHeaders:(NSDictionary<NSString *,NSString *> *)globalHeaders
{
    if (self = [super init]) {
        self.name = name;
        self.URL = URL;
        self.globalHeaders = globalHeaders;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

@end
