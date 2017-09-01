//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSNotificationCenter+Tests.h"

#import <SRGLetterbox/SRGLetterbox.h>

@implementation NSNotificationCenter (Tests)

- (id<NSObject>)addObserverForLetterboxControllerPlaybackStateDidChangeNotificationUsingBlock:(void (^)(NSNotification *notification))block
{
    return [self addObserverForName:SRGLetterboxControllerPlaybackStateDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        return block(notification);
    }];
}

@end
