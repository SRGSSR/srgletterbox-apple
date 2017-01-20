//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>

// The singleton can be only setup once. Do not perform in a test case setup
__attribute__((constructor)) static void SetupTestSingletonTracker(void)
{
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierTEST
                                                     comScoreVirtualSite:@"rts-app-test-v"
                                                     netMetrixIdentifier:@"test"];
}
