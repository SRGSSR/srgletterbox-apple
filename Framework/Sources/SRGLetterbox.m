//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"

#import <SRGDiagnostics/SRGDiagnostics.h>

__attribute__((constructor)) static void SRGLetterboxDiagnosticsInit(void)
{
    SRGDiagnosticsService *diagnosticsService = [SRGDiagnosticsService serviceWithName:@"SRGPlaybackMetrics"];
    diagnosticsService.submissionBlock = ^(NSDictionary * _Nonnull JSONDictionary, void (^ _Nonnull completionBlock)(BOOL)) {
        // TODO: Network request
        NSLog(@"Diagnostics report: %@", JSONDictionary);
        completionBlock(YES);
    };
}

NSString *SRGLetterboxMarketingVersion(void)
{
    return [NSBundle srg_letterboxBundle].infoDictionary[@"CFBundleShortVersionString"];
}
