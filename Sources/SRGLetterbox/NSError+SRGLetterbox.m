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
    // Check on SRGLetterbox underlying error or SRGMediaPlayer underlying error
    NSError *error = self;
    while (self != nil) {
        if (([error.domain isEqualToString:NSURLErrorDomain] || [error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork]) &&
            error.code == NSURLErrorNotConnectedToInternet) {
            return YES;
        }
        error = error.userInfo[NSUnderlyingErrorKey];
    }
    return NO;
}

@end
