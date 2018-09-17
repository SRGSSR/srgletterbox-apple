//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <libextobjc/libextobjc.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <SRGDiagnostics/SRGDiagnostics.h>
#import <SRGLetterbox/SRGLetterbox.h>

#import "LetterboxBaseTestCase.h"

NSString * const SRGLetterboxDiagnosticSentNotification = @"SRGLetterboxDiagnosticSentNotification";
NSString * const SRGLetterboxDiagnosticBodyKey = @"SRGLetterboxDiagnosticBodyKey";

static NSString * const OnDemandVideoURN = @"urn:swi:video:42844052";

@interface DiagnosticTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) SRGLetterboxController *controller;

@property (nonatomic, weak) id<OHHTTPStubsDescriptor> imageStub;

@end

@implementation DiagnosticTestCase

#pragma mark Setup and tear down

- (void)setUp {
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    self.controller = [[SRGLetterboxController alloc] init];
    
    [SRGDiagnosticsService serviceWithName:@"SRGPlaybackMetrics"].submissionInterval = SRGDiagnosticsMinimumSubmissionInterval;
    
    self.imageStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL isEqual:[NSURL URLWithString:@"https://srgsnitch.herokuapp.com/report"]];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGLetterboxDiagnosticSentNotification
                                                            object:self.controller
                                                          userInfo:@{ SRGLetterboxDiagnosticBodyKey : [request OHHTTPStubs_HTTPBody] }];
        
        return [[OHHTTPStubsResponse responseWithData:[NSJSONSerialization dataWithJSONObject:@{ @"success" : @YES } options:0 error:NULL]
                                                 statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}]
                requestTime:0.f
                responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
    self.imageStub.name = @"Diagnostic report";
}

- (void)tearDown {
    // Always ensure the player gets deallocated between tests
    [self.controller reset];
    self.controller = nil;
    
    [OHHTTPStubs removeStub:self.imageStub];
}

#pragma mark Tests

- (void)testReportPlayURN
{
    NSString *URN = OnDemandVideoURN;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxDiagnosticSentNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        NSData *HTTPBody = notification.userInfo[SRGLetterboxDiagnosticBodyKey];
        NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:HTTPBody options:0 error:NULL];
        
        XCTAssertEqualObjects(JSONDictionary[@"version"], @1);
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], [[NSBundle mainBundle] bundleIdentifier]);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/iOS/%@", SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        XCTAssertEqualObjects(JSONDictionary[@"standalone"], @NO);

        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertEqualObjects([NSURL URLWithString:JSONDictionary[@"playerResult"][@"url"]].scheme, @"https");
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"varnish"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertEqualObjects([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]].host, SRGIntegrationLayerProductionServiceURL().host);
        XCTAssertNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testReportOneOnlyPlayURN
{
    NSString *URN = OnDemandVideoURN;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxDiagnosticSentNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No other diagnostic sent notifications must be received.
    id diagnosticSentObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxDiagnosticSentNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Controller must not send twice the diagnostic report.");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:diagnosticSentObserver];
    }];
}

- (void)testReportPlayUnknownURN
{
    NSString *URN = @"urn:swi:video:_NO_ID_";
    
    [self expectationForNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self expectationForNotification:SRGLetterboxDiagnosticSentNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        NSData *HTTPBody = notification.userInfo[SRGLetterboxDiagnosticBodyKey];
        NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:HTTPBody options:0 error:NULL];
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], [[NSBundle mainBundle] bundleIdentifier]);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/iOS/%@", SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        XCTAssertEqualObjects(JSONDictionary[@"standalone"], @NO);
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNil(JSONDictionary[@"playerResult"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"varnish"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @404);
        XCTAssertEqualObjects([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]].host, SRGIntegrationLayerProductionServiceURL().host);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testReportPlayUnplayableResource
{
    self.controller.serviceURL = MMFServiceURL();
    
    NSString *URN = @"urn:rts:video:playlist500";
    
    [self expectationForNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [self expectationForNotification:SRGLetterboxDiagnosticSentNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        NSData *HTTPBody = notification.userInfo[SRGLetterboxDiagnosticBodyKey];
        NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:HTTPBody options:0 error:NULL];
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], [[NSBundle mainBundle] bundleIdentifier]);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/iOS/%@", SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");
        XCTAssertEqualObjects(JSONDictionary[@"standalone"], @NO);
        
        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertEqualObjects([NSURL URLWithString:JSONDictionary[@"playerResult"][@"url"]].scheme, @"https");
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"errorMessage"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"varnish"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertEqualObjects([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]].host, MMFServiceURL().host);
        XCTAssertNil(JSONDictionary[@"ilResult"][@"errorMessage"]);
        
        return YES;
    }];
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

- (void)testReportContentURLOverriding
{
    NSURL *overridingURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No diagnostic sent notifications must be received for content URL overriding.
    id diagnosticSentObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxDiagnosticSentNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Controller must not send the diagnostic report for content URL overriding.");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:diagnosticSentObserver];
    }];
}

@end
