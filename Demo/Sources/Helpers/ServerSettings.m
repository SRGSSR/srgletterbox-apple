//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ServerSettings.h"

@interface ServerSettings ()

@property (nonatomic) NSString *name;
@property (nonatomic) NSURL *URL;

@end

@implementation ServerSettings

#pragma mark Object lifecycle

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)URL
{
    if (self = [super init]) {
        self.name = name;
        self.URL = URL;
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
