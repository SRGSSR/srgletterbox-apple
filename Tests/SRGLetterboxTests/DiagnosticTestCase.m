//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

@import libextobjc;
@import OHHTTPStubs;
@import SRGContentProtection;
@import SRGDiagnostics;
@import SRGLetterbox;

NSString * const DiagnosticTestDidSendReportNotification = @"DiagnosticTestDidSendReportNotification";
NSString * const DiagnosticTestJSONDictionaryKey = @"DiagnosticTestJSONDictionary";

#if TARGET_OS_TV
static NSString * const DiagnosticTestCasePlatform = @"tvOS";
#else
static NSString * const DiagnosticTestCasePlatform = @"iOS";
#endif

@interface DiagnosticTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) SRGLetterboxController *controller;

@property (nonatomic, weak) id<HTTPStubsDescriptor> reportRequestStub;

@end

@implementation DiagnosticTestCase

#pragma mark Setup and tear down

- (void)setUp
{
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    self.controller = [[SRGLetterboxController alloc] init];
    
    [SRGDiagnosticsService serviceWithName:@"SRGPlaybackMetrics"].submissionInterval = SRGDiagnosticsMinimumSubmissionInterval;
    
    self.reportRequestStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL isEqual:[NSURL URLWithString:@"https://srgsnitch.herokuapp.com/report"]];
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:[request OHHTTPStubs_HTTPBody] options:0 error:NULL] ?: @{};
        [NSNotificationCenter.defaultCenter postNotificationName:DiagnosticTestDidSendReportNotification
                                                          object:nil
                                                        userInfo:@{ DiagnosticTestJSONDictionaryKey : JSONDictionary }];
        return [[HTTPStubsResponse responseWithData:[NSJSONSerialization dataWithJSONObject:@{ @"success" : @YES } options:0 error:NULL]
                                         statusCode:200
                                            headers:@{ @"Content-Type" : @"application/json" }] requestTime:0. responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
    self.reportRequestStub.name = @"Diagnostic report";
}

- (void)tearDown
{
    // Always ensure the player gets deallocated between tests
    [self.controller reset];
    self.controller = nil;
    
    [HTTPStubs removeStub:self.reportRequestStub];
}

#pragma mark Tests

- (void)testPlaybackReportForNonProtectedMedia
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    NSString *URN = OnDemandVideoURN;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"version"], @1);
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        XCTAssertNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"playerResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSinglePlaybackReportSubmission
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No other diagnostic report notification must be received.
    id diagnosticSentObserver = [NSNotificationCenter.defaultCenter addObserverForName:DiagnosticTestDidSendReportNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Controller must not send twice the diagnostic report.");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:diagnosticSentObserver];
    }];
}

- (void)testPlaybackReportForUnknownMedia
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    NSString *URN = @"urn:swi:video:_UNKNOWN_ID_";
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @404);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"errorMessage"]);
        XCTAssertNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        XCTAssertNil(JSONDictionary[@"playerResult"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportForBlockedMedia
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    NSString *URN = @"urn:srf:video:84135f7b-c58d-4a2d-b0b0-e8680581eede";
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"errorMessage"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"blockReason"], @"LEGAL");
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        XCTAssertNil(JSONDictionary[@"playerResult"]);
        
        return YES;
    }];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = YES;
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:settings];
    
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

- (void)testPlaybackReportForUnplayableMedia
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    self.controller.serviceURL = MMFServiceURL();
    
    NSString *URN = @"urn:rts:video:playlist500";
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"varnish"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNil(JSONDictionary[@"ilResult"][@"errorMessage"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"url"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

- (void)testPlaybackReportForOverriddenMedia
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    NSURL *overridingURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No diagnostic report notifications must be received for content URL overriding.
    id diagnosticSentObserver = [NSNotificationCenter.defaultCenter addObserverForName:DiagnosticTestDidSendReportNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Controller must not send diagnostic reports for content URL overriding.");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:diagnosticSentObserver];
    }];
}

- (void)testPlaybackReportForTokenProtectedMedia
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    NSString *URN = OnDemandVideoTokenURN;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"version"], @1);
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNotNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"tokenResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"tokenResult"][@"httpStatusCode"]);
        XCTAssertNotNil(JSONDictionary[@"tokenResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"tokenResult"][@"errorMessage"]);
        
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"playerResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportForConsecutiveMedias
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoTokenURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    __block BOOL firstReportSent = NO;
    __block BOOL secondReportSent = NO;
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        NSString *URN = JSONDictionary[@"urn"];
        if ([URN isEqualToString:OnDemandVideoURN]) {
            firstReportSent = YES;
        }
        else if ([URN isEqualToString:OnDemandVideoTokenURN]) {
            secondReportSent = YES;
        }
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return firstReportSent && secondReportSent;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportForSegmentSwitch
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:@"urn:rts:video:10248945" atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller switchToURN:@"urn:rts:video:10248943" withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], @"urn:rts:video:10248945");
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportForChapterSwitch
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = YES;
    
    NSString *URN1 = @"urn:rts:video:10248945";
    [self.controller playURN:URN1 atPosition:nil withPreferredSettings:settings];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN2 = @"urn:rts:video:10248943";
    [self.controller switchToURN:URN2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    __block BOOL firstReportSent = NO;
    __block BOOL secondReportSent = NO;
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        NSString *URN = JSONDictionary[@"urn"];
        if ([URN isEqualToString:URN1]) {
            XCTAssertNotNil(JSONDictionary[@"ilResult"]);
            firstReportSent = YES;
        }
        else if ([URN isEqualToString:URN2]) {
            XCTAssertNil(JSONDictionary[@"ilResult"]);
            secondReportSent = YES;
        }
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return firstReportSent && secondReportSent;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportForSwitchToBlockedChapter
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    // Simulate geoblocking
    self.controller.globalParameters = @{ @"forceLocation" : @"WW" };
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = YES;
    
    NSString *URN1 = @"urn:rts:video:11565846";
    [self.controller playURN:URN1 atPosition:nil withPreferredSettings:settings];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    // Blocked. Cannot be played
    NSString *URN2 = @"urn:rts:video:11565838";
    [self.controller switchToURN:URN2 withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    __block BOOL firstReportSent = NO;
    __block BOOL secondReportSent = NO;
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        NSString *URN = JSONDictionary[@"urn"];
        if ([URN isEqualToString:URN1]) {
            XCTAssertNotNil(JSONDictionary[@"ilResult"]);
            XCTAssertNotNil(JSONDictionary[@"playerResult"]);
            firstReportSent = YES;
        }
        else if ([URN isEqualToString:URN2]) {
            XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"blockReason"], @"GEOBLOCK");
            XCTAssertNotNil(JSONDictionary[@"ilResult"][@"errorMessage"]);
            XCTAssertNil(JSONDictionary[@"playerResult"]);
            secondReportSent = YES;
        }
        
        return firstReportSent && secondReportSent;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportAfterRestart
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    NSString *URN = OnDemandVideoURN;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        return YES;
    }];
    
    [self.controller restart];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testPlaybackReportForNotYetAvailableMedia
{
    self.controller.serviceURL = MMFServiceURL();
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:13];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"blockReason"], @"STARTDATE");
        XCTAssertNil(JSONDictionary[@"playerResult"]);
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertNil(JSONDictionary[@"ilResult"][@"blockReason"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        return YES;
    }];
    
    // Media starts playing automatically, just wait. A new report must be generated when playback starts
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testPlaybackReportForNonProtectedMediaChangedURN
{
    self.controller.serviceURL = MMFServiceURL();
    
    NSString *URN = MMFNonProtectedMediaChangedURN;
    
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"version"], @1);
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        XCTAssertNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"playerResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackReportForTokenProtectedMediaChangedURN
{
    // Report submission is disabled in public builds (tested once). Nothing to test here.
    if (SRGContentProtectionIsPublic()) {
        return;
    }
    
    self.controller.serviceURL = MMFServiceURL();
    
    NSString *URN = MMFProtectedMediaChangedURN;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:DiagnosticTestDidSendReportNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *JSONDictionary = notification.userInfo[DiagnosticTestJSONDictionaryKey];
        
        XCTAssertEqualObjects(JSONDictionary[@"version"], @1);
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], NSBundle.mainBundle.bundleIdentifier);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/%@/%@", DiagnosticTestCasePlatform, SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"playableAbroad"]);
        
        XCTAssertNotNil(JSONDictionary[@"tokenResult"]);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"tokenResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"tokenResult"][@"httpStatusCode"]);
        XCTAssertNotNil(JSONDictionary[@"tokenResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"tokenResult"][@"errorMessage"]);
        
        XCTAssertNil(JSONDictionary[@"drmResult"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNotNil([NSURL URLWithString:JSONDictionary[@"playerResult"][@"url"]]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testDisabledPlaybackReportInPublicBuilds
{
    if (! SRGContentProtectionIsPublic()) {
        return;
    }
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No diagnostic report notifications must be received in public builds
    id diagnosticSentObserver = [NSNotificationCenter.defaultCenter addObserverForName:DiagnosticTestDidSendReportNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Controller must not send diagnostic reports for public builds.");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:diagnosticSentObserver];
    }];
}

@end
