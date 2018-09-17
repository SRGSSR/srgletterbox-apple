//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <libextobjc/libextobjc.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <SRGLetterbox/SRGLetterbox.h>

NSString * const SRGLetterboxDiagnosticSentNotification = @"SRGLetterboxDiagnosticSentNotification";
NSString * const SRGLetterboxDiagnosticBodyKey = @"SRGLetterboxDiagnosticBodyKey";

static NSString * const OnDemandVideoURN = @"urn:swi:video:42844052";

@interface DiagnosticTestCase : XCTestCase

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) SRGLetterboxController *controller;

@property (nonatomic, weak) id<OHHTTPStubsDescriptor> imageStub;

@end

@implementation DiagnosticTestCase

#pragma mark Setup and tear down

- (void)setUp {
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    self.controller = [[SRGLetterboxController alloc] init];
    
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
        
        XCTAssertEqualObjects(JSONDictionary[@"urn"], URN);
        XCTAssertEqualObjects(JSONDictionary[@"screenType"], @"local");
        XCTAssertEqualObjects(JSONDictionary[@"networkType"], @"wifi");
        XCTAssertEqualObjects(JSONDictionary[@"browser"], [[NSBundle mainBundle] bundleIdentifier]);
        NSString *playerName = [NSString stringWithFormat:@"Letterbox/iOS/%@", SRGLetterboxMarketingVersion()];
        XCTAssertEqualObjects(JSONDictionary[@"player"], playerName);
        XCTAssertEqualObjects(JSONDictionary[@"environment"], @"preprod");

        XCTAssertNotNil(JSONDictionary[@"clientTime"]);
        XCTAssertNotNil(JSONDictionary[@"device"]);
        
        XCTAssertNotNil(JSONDictionary[@"playerResult"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"url"]);
        XCTAssertNotNil(JSONDictionary[@"playerResult"][@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"duration"]);
        
        XCTAssertNotNil(JSONDictionary[@"ilResult"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"duration"]);
        XCTAssertNotNil(JSONDictionary[@"ilResult"][@"varnish"]);
        XCTAssertEqualObjects(JSONDictionary[@"ilResult"][@"httpStatusCode"], @200);
        XCTAssertEqualObjects([NSURL URLWithString:JSONDictionary[@"ilResult"][@"url"]].host, SRGIntegrationLayerProductionServiceURL().host);
        
        return YES;
    }];
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:60. handler:nil];
}

@end
