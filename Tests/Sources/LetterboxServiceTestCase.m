//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <XCTest/XCTest.h>

static NSURL *ServiceTestURL(void)
{
    return SRGIntegrationLayerTestServiceURL();
}

@interface LetterboxServiceTestCase : XCTestCase

@end

@implementation LetterboxServiceTestCase

- (void)testObjects
{
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    XCTAssertNotNil(service);
    XCTAssertNotNil(service.controller);
}

- (void)testPlayback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        SRGMedia *media = medias.firstObject;
        XCTAssertNotNil(media);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

@end
