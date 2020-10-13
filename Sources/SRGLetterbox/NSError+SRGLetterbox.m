//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSError+SRGLetterbox.h"

@implementation NSError (SRGLetterbox)

#pragma mark Class methods

- (BOOL)srg_letterbox_isNotConnectedToInternet
{
    NSError *error = self;
    while (error) {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
            return YES;
        }
        
        if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] && error.code == kCFURLErrorNotConnectedToInternet) {
            return YES;
        }
        
        error = error.userInfo[NSUnderlyingErrorKey];
    }
    return NO;
}

@end
