//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SceneDelegate.h"

#import "Application.h"
#import "ServerSettings.h"
#import "UIViewController+LetterboxDemo.h"

@import libextobjc;

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    if ([scene isKindOfClass:UIWindowScene.class]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        [self.window makeKeyAndVisible];
        
        self.window.rootViewController = ApplicationRootViewController();
        
        [self handleURLContexts:connectionOptions.URLContexts];
    }
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    [self handleURLContexts:URLContexts];
}

#pragma mark Custom scheme urls

// Open [scheme]://open?media=[media_urn] (optional &server=[server_name])
- (void)handleURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    // FIXME: Works as long as only one context is received
    UIOpenURLContext *URLContext = URLContexts.anyObject;
    if (! URLContext) {
        return;
    }
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URLContext.URL resolvingAgainstBaseURL:YES];
    if ([URLComponents.host.lowercaseString isEqualToString:@"media"]) {
        NSString *mediaURN = URLComponents.path.lastPathComponent;
        if (mediaURN) {
            NSURL *serviceURL = nil;
            NSString *server = [self valueFromURLComponents:URLComponents withParameterName:@"server"];
            if (server) {
                serviceURL = LetterboxDemoServiceURLForKey(server);
            }
            [self.window.rootViewController openPlayerWithURN:mediaURN serviceURL:serviceURL];
        }
    }
}

#pragma mark Custom URL scheme support

- (NSString *)valueFromURLComponents:(NSURLComponents *)URLComponents withParameterName:(NSString *)parameterName
{
    NSParameterAssert(URLComponents);
    NSParameterAssert(parameterName);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(NSURLQueryItem.new, name), parameterName];
    NSURLQueryItem *queryItem = [URLComponents.queryItems filteredArrayUsingPredicate:predicate].firstObject;
    if (! queryItem) {
        return nil;
    }
    
    return queryItem.value;
}

@end
