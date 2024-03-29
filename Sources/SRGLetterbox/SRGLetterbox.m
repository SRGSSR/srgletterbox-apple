//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterbox.h"

#import "SRGLetterboxLogger.h"

@import SRGContentProtection;
@import SRGDiagnostics;
@import SRGNetwork;

#warning "Letterbox will be sunset in August 2025. Please upgrade to Pillarbox (https://github.com/SRGSSR/pillarbox-apple)."

__attribute__((constructor)) static void SRGLetterboxDiagnosticsInit(void)
{
    // SRGPlaybackMetrics anatomy:
    // ---------------------------
    //                                 ┌─────────────────┐
    //                                 │                 │
    //       ┌─────────────────┐       │  The media URL  │
    //       │  Letterbox is   │       │received from the│                              ┌──────────────────┐
    //       │ asked to play a │       │  IL is played   │                              │  Media playback  │
    //       │      media      │       │                 │                              │      starts      │
    //       └─────────────────┘       └─────────────────┘                              └──────────────────┘
    //                │                         │                                                 │
    //                │                         │                                                 │
    //                │                         │                                                 │
    //                │                         │    ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
    //                │                         │            playerResult.duration        │┌──────┘
    //                │                         │    └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
    //                │                         │    ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─               │
    //                │   ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │      tokenResult.duration │              │
    //  ──────────────▼──▲─ ilResult.duration ──▼───▲┤  drmResult.duration  ───────▲───────▼──────────────────▶
    //                │  │└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘     │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ ┌────┘       │                 time
    //                   │                          │                         │
    //                │  │                          │                         │            │
    //                   └────────────┐             └──────────┐     ┌─────────────────┐
    //                │               │                        │     │ Media buffering │   │
    //                                │                        │     │     starts      │
    //                │               │                        │     └─────────────────┘   │
    //                                │                        │
    //                │      ┌─────────────────┐       ┌───────────────┐                   │
    //                       │  The media is   │       │  Token / DRM  │
    //                │      │ requested from  │       │keys retrieval │                   │
    //                       │     the IL      │       │    starts     │
    //                │      └─────────────────┘       └───────────────┘                   │
    //
    //                │                                                                    │
    //
    //                │                                                                    │
    //                 ◀──────────────────────────────────────────────────────────────────▶
    //                                         duration in case of
    //                                         successful playback
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        [SRGDiagnosticsService serviceWithName:@"SRGPlaybackMetrics"].submissionBlock = ^(NSDictionary * _Nonnull JSONDictionary, void (^ _Nonnull completionBlock)(BOOL)) {
            NSURL *diagnosticsServiceURL = [NSURL URLWithString:@"https://srgsnitch.herokuapp.com/report"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:diagnosticsServiceURL];
            request.HTTPMethod = @"POST";
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:NULL];
            
            [[[SRGRequest dataRequestWithURLRequest:request session:NSURLSession.sharedSession completionBlock:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                BOOL success = (error == nil);
                SRGLetterboxLogInfo(@"diagnostics", @"SRGPlaybackMetrics report %@: %@", success ? @"sent" : @"not sent", JSONDictionary);
                completionBlock(success);
            }] requestWithOptions:SRGRequestOptionBackgroundCompletionEnabled] resume];
        };
    });
}

NSString *SRGLetterboxMarketingVersion(void)
{
    return @MARKETING_VERSION;
}
