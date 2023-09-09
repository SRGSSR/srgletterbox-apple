//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;

// The singleton can be only setup once. Do not perform in a test case setup
void SetupTestSingletonTracker(void)
{
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierSRG
                                                                                                       sourceKey:@"39ae8f94-595c-4ca4-81f7-fb7748bd3f04"
                                                                                                        siteName:@"srg-test-letterbox-apple"];
    configuration.unitTesting = YES;
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration];
}
