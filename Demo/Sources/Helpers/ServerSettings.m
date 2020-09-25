//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ServerSettings.h"

@import libextobjc;
@import SRGDataProvider;

NSURL *LetterboxDemoMMFServiceURL(void)
{
    NSString *serviceURLString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"PlayMMFServiceURL"];
    NSURL *serviceURL = (serviceURLString.length > 0) ? [NSURL URLWithString:serviceURLString] : nil;
    return serviceURL ?: [NSURL URLWithString:@"https://play-mmf.herokuapp.com/integrationlayer"];
}

NSURL *LetterboxDemoServiceURLForKey(NSString *key)
{
    NSInteger index = [ServerSettings.serverSettings indexOfObjectPassingTest:^BOOL(ServerSettings * _Nonnull serverSettings, NSUInteger idx, BOOL * _Nonnull stop) {
        return [serverSettings.name caseInsensitiveCompare:key] == NSOrderedSame;
    }];
    if (index != NSNotFound) {
        return ServerSettings.serverSettings[index].URL;
    }
    else {
        return nil;
    }
}

NSString *LetterboxDemoServiceNameForKey(NSString *key)
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ServerSettings * _Nullable serverSettings, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [serverSettings.name caseInsensitiveCompare:key] == NSOrderedSame;
    }];
    return [ServerSettings.serverSettings filteredArrayUsingPredicate:predicate].firstObject.name;
}

NSString *LetterboxDemoServiceNameForURL(NSURL *URL)
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(ServerSettings.new, URL), URL];
    return [ServerSettings.serverSettings filteredArrayUsingPredicate:predicate].firstObject.name;
}

@interface ServerSettings ()

@property (nonatomic) NSString *name;
@property (nonatomic) NSURL *URL;

@end

@implementation ServerSettings

#pragma mark Class getter

+ (NSArray<ServerSettings *> *)serverSettings
{
    static dispatch_once_t s_onceToken;
    static NSArray<ServerSettings *> *s_serverSettings;
    dispatch_once(&s_onceToken, ^{
        s_serverSettings = @[[[ServerSettings alloc] initWithName:NSLocalizedString(@"Production", nil) URL:SRGIntegrationLayerProductionServiceURL()],
                             [[ServerSettings alloc] initWithName:NSLocalizedString(@"Stage", nil) URL:SRGIntegrationLayerStagingServiceURL()],
                             [[ServerSettings alloc] initWithName:NSLocalizedString(@"Test", nil) URL:SRGIntegrationLayerTestServiceURL()],
                             [[ServerSettings alloc] initWithName:NSLocalizedString(@"Play MMF", nil) URL:LetterboxDemoMMFServiceURL()]];
    });
    return s_serverSettings;
}

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
