//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxLogger.h"

#import <SRGDiagnostics/SRGDiagnostics.h>

/**
 *  Diagnostics service URL key in bundle information dictionnary.
 */
NSString * const SRGLetterboxDiagnosticsServiceURLKey = @"DiagnosticsServiceURL";

__attribute__((constructor)) static void SRGLetterboxDiagnosticsInit(void)
{
    [SRGDiagnosticsService serviceWithName:@"SRGPlaybackMetrics"].submissionBlock = ^(NSDictionary * _Nonnull JSONDictionary, void (^ _Nonnull completionBlock)(BOOL)) {
        NSString *diagnosticsServiceURLString = [[NSBundle srg_letterboxBundle] objectForInfoDictionaryKey:SRGLetterboxDiagnosticsServiceURLKey];
        NSURL *diagnosticsServiceURL = (diagnosticsServiceURLString.length > 0) ? [NSURL URLWithString:diagnosticsServiceURLString] : nil;
        if (diagnosticsServiceURL) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:diagnosticsServiceURL];
            request.HTTPMethod = @"POST";
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:NULL];
            [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                SRGLetterboxLogInfo(@"diagnostics", @"SRGPlaybackMetrics report %@: %@", (error != nil) ? @"sent" : @"not sent", JSONDictionary);
                completionBlock(error != nil);
            }] resume];
        }
        else {
            SRGLetterboxLogInfo(@"diagnostics", @"SRGPlaybackMetrics report: %@", JSONDictionary);
            completionBlock(YES);
        }
    };
}

NSString *SRGLetterboxMarketingVersion(void)
{
    return [NSBundle srg_letterboxBundle].infoDictionary[@"CFBundleShortVersionString"];
}
