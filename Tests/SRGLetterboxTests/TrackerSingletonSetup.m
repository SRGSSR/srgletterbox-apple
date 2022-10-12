//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;

// The singleton can be only setup once. Do not perform in a test case setup
__attribute__((constructor)) static void SetupTestSingletonTracker(void)
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                                                                       sourceKey:@"39ae8f94-595c-4ca4-81f7-fb7748bd3f04"
                                                                                                        siteName:@"rts-app-test-v"];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration];
}
