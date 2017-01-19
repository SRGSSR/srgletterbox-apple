//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <XCTest/XCTest.h>

static NSURL *ServiceTestURL(void)
{
    return SRGIntegrationLayerTestServiceURL();
}

@interface LetterboxServiceTestCase : XCTestCase

@end

@implementation LetterboxServiceTestCase

#pragma mark Helpers

- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(void (^)(void))handler
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Wait for %@ seconds", @(timeInterval)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
        handler ? handler() : nil;
    });
    return expectation;
}

#pragma mark Setup and teardown

- (void)tearDown
{
    // Return to a known state after playback ended
    [[SRGLetterboxService sharedService] reset];
}

#pragma mark Tests

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
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    XCTAssertNil(service.media);
    XCTAssertNil(service.mediaComposition);
    XCTAssertNil(service.error);
    
    // Wait until the stream is playing, at which time we expect the media composition to be available. Any update in between
    // must have correct media information
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServiceMediaKey], media);
        XCTAssertNil(notification.userInfo[SRGLetterboxServicePreviousMediaCompositionKey]);
        
        if (! notification.userInfo[SRGLetterboxServiceMediaCompositionKey]) {
            XCTAssertNil(notification.userInfo[SRGLetterboxServicePreviousMediaKey]);
            return NO;
        }
        else {
            XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaKey], media);
            return YES;
        }
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
    
    XCTAssertEqualObjects(service.media, media);
    XCTAssertNil(service.mediaComposition);
    XCTAssertNil(service.error);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(service.media, media);
    XCTAssertNotNil(service.mediaComposition);
    XCTAssertNil(service.error);
}

- (void)testSameMediaPlaybackWhileAlreadyPlaying
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        XCTAssertNotNil(media);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect no change when trying to play the same media
    id metadataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxServiceMetadataDidChangeNotification object:service queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no playback state change when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:metadataObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSameMediaPlaybackWhilePaused
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        XCTAssertNotNil(media);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [[SRGLetterboxService sharedService].controller pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect only a player state change notification, no metadata change notification
    id metadataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxServiceMetadataDidChangeNotification object:service queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:metadataObserver];
    }];
}

- (void)testMediaChange
{
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Request 1 succeeded"];
    
    __block SRGMedia *media1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media1 = medias.firstObject;
        XCTAssertNotNil(media1);
        [expectation1 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // Wait until the stream is playing with media composition information available
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxServiceMediaCompositionKey] != nil;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media1 withPreferredQuality:SRGQualityNone];
    
    XCTAssertEqualObjects(service.media, media1);
    XCTAssertNil(service.mediaComposition);
    XCTAssertNil(service.error);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGMediaComposition *mediaComposition1 = service.mediaComposition;
    XCTAssertNotNil(mediaComposition1);
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Request 2 succeeded"];
    
    __block SRGMedia *media2 = nil;
    [[dataProvider videosWithUids:@[@"42851050"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media2 = medias.firstObject;
        XCTAssertNotNil(media2);
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Wait until the stream is playing with media composition information available
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServiceMediaKey], media2);
        
        if (! notification.userInfo[SRGLetterboxServiceMediaCompositionKey]) {
            XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaKey], media1);
            XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaCompositionKey], mediaComposition1);
            return NO;
        }
        else {
            XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaKey], media2);
            XCTAssertNil(notification.userInfo[SRGLetterboxServicePreviousMediaCompositionKey]);
            return YES;
        }
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media2 withPreferredQuality:SRGQualityNone];
    
    XCTAssertEqualObjects(service.media, media2);
    XCTAssertNil(service.mediaComposition);
    XCTAssertNil(service.error);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(service.media, media2);
    XCTAssertNotNil(service.mediaComposition);
    XCTAssertNil(service.error);
}

- (void)testReset
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        XCTAssertNotNil(media);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // Wait until the stream is playing with media composition information available
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxServiceMediaCompositionKey] != nil;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media withPreferredQuality:SRGQualityNone];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaKey], media);
        XCTAssertNil(notification.userInfo[SRGLetterboxServiceMediaKey]);
        
        XCTAssertNotNil(notification.userInfo[SRGLetterboxServicePreviousMediaCompositionKey]);
        XCTAssertNil(notification.userInfo[SRGLetterboxServiceMediaCompositionKey]);
        return YES;
    }];
    
    // Reset
    [service reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil(service.media);
    XCTAssertNil(service.mediaComposition);
    XCTAssertNil(service.error);
}

- (void)testResumeWithIdleService
{
    XCTestExpectation *mediaCompositionExpectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMediaComposition *mediaComposition = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider mediaCompositionForVideoWithUid:@"42844052" completionBlock:^(SRGMediaComposition * _Nullable retrievedMediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(retrievedMediaComposition);
        mediaComposition = retrievedMediaComposition;
        [mediaCompositionExpectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *playExpectation = [self expectationWithDescription:@"Play succeeded"];
    
    SRGLetterboxController *controller = [[SRGLetterboxController alloc] init];
    [controller playMediaComposition:mediaComposition withPreferredProtocol:SRGProtocolNone preferredQuality:SRGQualityNone userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
        [playExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNil(notification.userInfo[SRGLetterboxServicePreviousMediaKey]);
        XCTAssertNotNil(notification.userInfo[SRGLetterboxServiceMediaKey]);
        
        XCTAssertNil(notification.userInfo[SRGLetterboxServicePreviousMediaCompositionKey]);
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServiceMediaCompositionKey], mediaComposition);
        return YES;
    }];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    [service resumeFromController:controller];
    
    XCTAssertNotNil(service.media);
    XCTAssertEqualObjects(service.mediaComposition, mediaComposition);
    XCTAssertNil(service.error);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testResumeWithPlayingService
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request succeeded"];
    
    __block SRGMedia *media1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media1 = medias.firstObject;
        XCTAssertNotNil(media1);
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // Wait until the media composition is available
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:service handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxServiceMediaCompositionKey] != nil;
    }];
    
    [[SRGLetterboxService sharedService] playMedia:media1 withPreferredQuality:SRGQualityNone];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    SRGMediaComposition *mediaComposition1 = service.mediaComposition;
    
    XCTestExpectation *mediaCompositionExpectation = [self expectationWithDescription:@"Media composition request succeeded"];
    
    __block SRGMediaComposition *mediaComposition2 = nil;
    [[dataProvider mediaCompositionForVideoWithUid:@"42851050" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        mediaComposition2 = mediaComposition;
        [mediaCompositionExpectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *playExpectation = [self expectationWithDescription:@"Play succeeded"];
    
    SRGLetterboxController *controller = [[SRGLetterboxController alloc] init];
    [controller playMediaComposition:mediaComposition2 withPreferredProtocol:SRGProtocolNone preferredQuality:SRGQualityNone userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
        [playExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect no player status change
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:service.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no playback state change");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    [self expectationForNotification:SRGLetterboxServiceMetadataDidChangeNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaKey], media1);
        XCTAssertNotNil(notification.userInfo[SRGLetterboxServiceMediaKey]);
        
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServicePreviousMediaCompositionKey], mediaComposition1);
        XCTAssertEqualObjects(notification.userInfo[SRGLetterboxServiceMediaCompositionKey], mediaComposition2);
        return YES;
    }];
    
    [service resumeFromController:controller];
    
    XCTAssertNotNil(service.media);
    XCTAssertEqualObjects(service.mediaComposition, mediaComposition2);
    XCTAssertNil(service.error);
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

@end
