//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"
#import "TrackerSingletonSetup.h"

@import libextobjc;
@import SRGDataProviderNetwork;
@import SRGLetterbox;

// Imports required to test internals
#import "SRGLetterboxController+Private.h"

@interface PlaybackTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation PlaybackTestCase

#pragma mark Setup and tear down

+ (void)setUp
{
    SetupTestSingletonTracker();
}

- (void)setUp
{
    self.controller = [[SRGLetterboxController alloc] init];
}

- (void)tearDown
{
    // Always ensure the player gets deallocated between tests
    [self.controller reset];
    self.controller = nil;
}

#pragma mark Tests

- (void)testDeallocationWhileIdle
{
    __weak SRGLetterboxController *weakController = self.controller;
    
    @autoreleasepool {
        self.controller = nil;
    }
    
    XCTAssertNil(weakController);
}

- (void)testDeallocationAfterPlayback
{
    __weak SRGLetterboxController *weakController = self.controller;
    @autoreleasepool {
        [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
        
        [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
        }];
        
        [self.controller reset];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
        
        self.controller = nil;
    }
    
    XCTAssertNil(weakController);
}

- (void)testPlayURN
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertFalse(self.controller.loading);
}

- (void)testPlayURNAtTime
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGPosition *position = [SRGPosition positionAtTimeInSeconds:15.];
    [self.controller playURN:OnDemandVideoURN atPosition:position withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(CMTimeGetSeconds(self.controller.currentTime), 15.);
}

- (void)testPlayMedia
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media retrieved"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    [[dataProvider mediasWithURNs:@[OnDemandVideoURN] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        media = medias.firstObject;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(media);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playMedia:media atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, media.URN);
    XCTAssertEqualObjects(self.controller.media, media);
    XCTAssertEqualObjects(self.controller.fullLengthMedia, media);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, media.URN);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertFalse(self.controller.loading);
}

- (void)testPlayMediaSegment
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media retrieved"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    [[dataProvider mediasWithURNs:@[OnDemandLongVideoSegmentURN] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        media = medias.firstObject;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(media);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playMedia:media atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, media.URN);
    XCTAssertEqualObjects(self.controller.media, media);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, OnDemandLongVideoURN);
    XCTAssertEqualObjects(self.controller.fullLengthMedia.URN, OnDemandLongVideoURN);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testPlayRightAfterPrepare
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    NSString *URN = OnDemandVideoURN;
    [self.controller prepareToPlayURN:URN atPosition:nil withPreferredSettings:nil completionHandler:nil];
    [self.controller play];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testStop
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle);
        XCTAssertNotNil(self.controller.URN);
        XCTAssertNotNil(self.controller.media);
        XCTAssertNotNil(self.controller.mediaComposition);
        XCTAssertNil(self.controller.error);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self.controller stop];
    
    XCTAssertNotNil(self.controller.URN);
    XCTAssertNotNil(self.controller.media);
    XCTAssertNotNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testReset
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertTrue([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle);
        XCTAssertNil(self.controller.URN);
        XCTAssertNil(self.controller.media);
        XCTAssertNil(self.controller.mediaComposition);
        XCTAssertNil(self.controller.error);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self.controller reset];
    
    XCTAssertNil(self.controller.URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayUnknownURN
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNotNil(self.controller.error);
        XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotFound);
        XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:@"urn:rts:video:1234" atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotFound);
    XCTAssertFalse(self.controller.loading);
    
    // Metadata updates must not erase playback errors
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotFound);
}

- (void)testPlayUnplayableResource
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNotNil(self.controller.error);
        XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
        XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:@"urn:rts:video:_playlist500" atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:60. handler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
    
    // Metadata updates must not erase playback errors
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
    XCTAssertFalse(self.controller.loading);
}

- (void)testPlayHDSOnlyResource
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNotNil(self.controller.error);
        XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
        XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playURN:@"urn:rts:video:_onlyHDS" atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    
    [self waitForExpectationsWithTimeout:60. handler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
    
    // Metadata updates must not erase playback errors
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
}

- (void)testPlayAfterStop
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testRestartLiveOnlyAfterTokenExpiration
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.streamType = SRGStreamTypeLive;
    
    // FIXME: Restore `LiveVideoURN` URN when IL fixed MediaComposition on segment (no more 400 return)
    [self.controller playURN:LiveVideo2URN atPosition:nil withPreferredSettings:settings];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // The token expires after 30 seconds. Wait a little bit more to be sure it has expired
    [self expectationForElapsedTimeInterval:40. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:45. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayAfterReset
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player cannot be restarted with a play after a reset. No event expected");
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testTogglePlayPause
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTogglePlayPauseAfterStop
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTogglePlayPauseAfterReset
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player cannot be restarted with a play after a reset. No event expected");
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testPlaybackMetadata
{
    XCTAssertNil(self.controller.URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    // Media and composition not immediately available, fetched by the controller
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.error);
    
    [self.controller reset];
    
    XCTAssertNil(self.controller.URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
}

- (void)testSameMediaPlaybackWithCompletionHandler
{
    XCTestExpectation *completionHandlerExpectation1 = [self expectationWithDescription:@"Completion handler"];
    [self.controller prepareToPlayURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil completionHandler:^{
        [completionHandlerExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self.controller play];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *completionHandlerExpectation2 = [self expectationWithDescription:@"Completion handler"];
    [self.controller prepareToPlayURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil completionHandler:^{
        [completionHandlerExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testSameMediaPlaybackWhileAlreadyPlaying
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect no change when trying to play the same media
    id metadataObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no playback state change when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:metadataObserver];
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSameMediaPlaybackWhilePaused
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect only a player state change notification, no metadata change notification
    id metadataObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:metadataObserver];
    }];
}

- (void)testPlaybackStateTransitions
{
    BOOL (^expectationHandler)(NSNotification * _Nonnull notification) = ^BOOL(NSNotification * _Nonnull notification) {
        SRGMediaPlayerPlaybackState currentState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        SRGMediaPlayerPlaybackState previousState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
        XCTAssertTrue(currentState != previousState);
        return YES;
    };
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller prepareToPlayURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil completionHandler:nil];
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller play];
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller pause];
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller reset];
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testPlaybackStateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.controller keyPath:@"playbackState" expectedValue:@(SRGMediaPlayerPlaybackStatePreparing)];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testContentURLOverriding
{
    NSURL *overridingURL = [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    self.controller.updateInterval = 10.;
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertEqualObjects(self.controller.mediaPlayerController.contentURL, overridingURL);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change with an overriding URL, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Wait for a while. No playback notifications must be received
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change with an overriding URL, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)test360ContentURLOverriding
{
    NSURL *overridingURL = [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    self.controller.updateInterval = 10.;
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.controller.serviceURL];
    [[dataProvider mediaCompositionForURN:OnDemand360VideoURN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        media = mediaComposition.fullLengthMedia;
        
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playMedia:media atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, media.URN);
    XCTAssertEqualObjects(self.controller.media, media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertEqualObjects(self.controller.mediaPlayerController.contentURL, overridingURL);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertEqual(self.controller.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
}

- (void)testStartTimeForContentURLOverriding
{
    NSURL *overridingURL = [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    self.controller.updateInterval = 10.;
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGPosition *position = [SRGPosition positionAtTimeInSeconds:15.];
    [self.controller playURN:OnDemandLongVideoURN atPosition:position withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqual(CMTimeGetSeconds(self.controller.currentTime), 15.);
}

- (void)testUninterruptedOnDemandFullLengthPlayback
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a full length, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a full length, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testUninterruptedOnDemandSegmentPlayback
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNotEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainSegment.URN, URN);
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testUninterruptedOnDemandPlaybackAfterSegmentSelection
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    [self.controller switchToSubdivision:self.controller.mediaComposition.mainChapter.segments[2] withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when selecting a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when selecting a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testUninterruptedLivePlayback
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = LiveVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNotNil(self.controller.URN);
    XCTAssertNotNil(self.controller.media.URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a stop from the user.");
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when stoping playback, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
}

- (void)testMediaNotYetAvailable
{
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    // Media starts in 7 seconds and is available 7 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonStartDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotAvailable);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxTimeAvailabilityKey] integerValue], SRGTimeAvailabilityNotYetAvailable);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotAvailable);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxTimeAvailabilityKey] integerValue], SRGTimeAvailabilityNotAvailableAnymore);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    // Attempt to play again and wait for a while. No playback notifications must be received
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
}

- (void)testMediaAvailable
{
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:15];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testMediaNotAvailableAnymore
{
    self.controller.serviceURL = MMFServiceURL();
    
    // Wait for a while. No playback notifications must be received
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available anymore.");
    }];
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not available anymore On Demand media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-15];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testMediaAvailableWithServerCacheInconsistency
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media started 1 second before and is available 20 seconds, but the server doesn't remove the blocking reason
    // STARTDATE on time.
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-1];
    NSDate *endDate = [startDate dateByAddingTimeInterval:20];
    NSString *URN = MMFCachedScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonStartDate);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMediaComposition *mediaComposition = notification.userInfo[SRGLetterboxMediaCompositionKey];
        return mediaComposition && [mediaComposition.mainChapter blockingReasonAtDate:NSDate.date] == SRGBlockingReasonNone;
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing after a metadata udpate
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
}

- (void)testMediaWithOverriddenURLNotYetAvailable
{
    self.controller.serviceURL = MMFServiceURL();
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    };
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.controller.serviceURL];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        media = mediaComposition.fullLengthMedia;
        
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Wait for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller playMedia:media atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonStartDate);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason has been received.");
    }];
    
    // Attempt to play again and wait for a while. No playback notifications must be received since the media is not
    // available anymore
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
    }];
}

- (void)testResourceChangedWhenStopped
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFURLChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    
    NSURL *firstURL = self.controller.mediaPlayerController.contentURL;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // URL changes while idle must not lead to playback state changes.
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when stopped.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    // A URL change occurs while the player is idle.
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNil(self.controller.mediaPlayerController.contentURL);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNotEqualObjects(self.controller.mediaPlayerController.contentURL, firstURL);
}

- (void)testBlockingReasonAppearance
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFBlockingReasonChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    
    // A blocking reason appearing while playing must stop playback
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // A blocking reason appears.
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonGeoblocking);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeBlocked);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonGeoblocking);
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testBlockingReasonDisappearance
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-5];
    NSDate *endDate = [startDate dateByAddingTimeInterval:10];
    NSString *URN = MMFBlockingReasonChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonGeoblocking);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeBlocked);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonGeoblocking);
    
    // The blocking reason disappears
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    
    // Wait until the stream is playing
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPeriodicUpdatesForLivestream
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // FIXME: Restore `LiveVideoURN` URN when IL fixed MediaComposition on segment (no more 400 return)
    [self.controller playURN:LiveVideo2URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    // An update must occur automatically
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPeriodicUpdatesForOnDemandStream
{
    self.controller.updateInterval = 10.;
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    // An update must occur automatically
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testLoadingWhileSeeking
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(self.controller.loading);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking) {
            XCTAssertTrue(self.controller.loading);
            return NO;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            XCTAssertFalse(self.controller.loading);
            return YES;
        }
        else {
            return NO;
        }
    }];
    
    CMTime seekTime = CMTimeMakeWithSeconds(40., NSEC_PER_SEC);
    [self.controller seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(self.controller.loading);
}

- (void)testLoadingKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.controller keyPath:@"loading" expectedValue:@YES];
    
    [self.controller playURN:MMFLiveDVRVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.controller keyPath:@"loading" expectedValue:@NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

@end
