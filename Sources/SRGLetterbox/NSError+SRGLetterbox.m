//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSError+SRGLetterbox.h"

@implementation NSError (SRGLetterbox)

#pragma mark Class methods

- (NSError *)srg_letterboxNoNetworkError
{
    NSError *error = self;
    while (error) {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
            return error;
        }
        
        if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] && error.code == kCFURLErrorNotConnectedToInternet) {
            return error;
        }
        
        error = error.userInfo[NSUnderlyingErrorKey];
    }
    return nil;
}

- (NSError *)srg_letterboxUnderlyingError
{
    NSError *error = self;
    while (error.userInfo[NSUnderlyingErrorKey]) {
        error = error.userInfo[NSUnderlyingErrorKey];
    }
    return error;
}

@end
