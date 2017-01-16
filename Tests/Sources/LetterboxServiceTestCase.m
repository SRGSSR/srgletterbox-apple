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

- (void)testPlaybackMetadata
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        XCTAssertNotNil(media);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // Wait until the stream is playing, at which time we expect the media composition to be available. Any update in between
    // must have correct media information
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServiceMediaKey], media);
        return notification.userInfo[SRGLetterboxServiceMediaCompositionKey] != nil;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media withDataProvider:dataProvider preferredQuality:SRGQualityHD];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
