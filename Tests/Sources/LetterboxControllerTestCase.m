//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>

#import "LetterboxBaseTestCase.h"

// Imports required to test internals
#import "SRGLetterboxController+Private.h"

static NSString * const OnDemandVideoURN = @"urn:swi:video:42844052";
static NSString * const OnDemand360VideoURN = @"urn:rts:video:8414077";
static NSString * const OnDemandLongVideoURN = @"urn:srf:video:2c685129-bad8-4ea0-93f5-0d6cff8cb156";
static NSString * const OnDemandLongVideoSegmentURN = @"urn:srf:video:5fe1618a-b710-42aa-ac8a-cb9eabf42426";
static NSString * const OnDemandAudioWithChaptersURN = @"urn:rts:audio:9355007";
static NSString * const LiveOnlyVideoURN = @"urn:rsi:video:livestream_La1";
static NSString * const LiveDVRVideoURN = @"urn:rts:video:1967124";
static NSString * const MMFOnDemandLongVideoURN = @"urn:rts:video:8992584";
static NSString * const MMFOnDemandLongVideoGeoblockSegmentURN = @"urn:rts:video:8992624";

static NSString *MMFScheduledOnDemandVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_bipbop_basic_delay_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSString *MMFCachedScheduledOnDemandVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_bipbop_basic_cacheddelay_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSString *MMFURLChangeVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_mediaplayer_dvr_killswitch_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSString *MMFBlockingReasonChangeVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_mediaplayer_dvr_geoblocked_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSString *MMFSwissTXTFullDVRURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_rts_info_fulldvr_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSString *MMFSwissTXTLimitedDVRURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_rts_info_liveonly_limiteddvr_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSString *MMFSwissTXTLiveOnlyURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_rts_info_liveonly_delay_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

static NSURL *MMFServiceURL(void)
{
    return [NSURL URLWithString:@"https://play-mmf.herokuapp.com"];
}

@interface LetterboxControllerTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation LetterboxControllerTestCase

#pragma mark Setup and tear down

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"
    __weak SRGLetterboxController *weakController = self.controller;
    
    @autoreleasepool {
        self.controller = nil;
    }
    
    XCTAssertNil(weakController);
#pragma clang diagnostic pop
}

- (void)testDeallocationWhilePlaying
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"
    __weak SRGLetterboxController *weakController = self.controller;    
    @autoreleasepool {
        // When no reference retains the player, playback must gracefully stop. Deallocation will occur right afterwards.
        [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
        }];
        
        [self.controller playURN:OnDemandVideoURN standalone:NO];
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
        
        [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
            return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
        }];
        
        // Chicken and egg problem: We ensure the idle state can be reached so that the LB controller gets deallocated
        [self.controller reset];
        
        self.controller = nil;
        
        [self waitForExpectationsWithTimeout:30. handler:nil];
    }
    
    XCTAssertNil(weakController);
#pragma clang diagnostic pop
}

- (void)testPlayURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
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

- (void)testPlayMedia
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media retrieved"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    [[dataProvider mediasWithURNs:@[OnDemandVideoURN] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(media);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playMedia:media standalone:NO];
    
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
    [[dataProvider mediasWithURNs:@[OnDemandLongVideoSegmentURN] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(media);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playMedia:media standalone:NO];
    
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
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    NSString *URN = OnDemandVideoURN;
    [self.controller prepareToPlayURN:URN standalone:NO withCompletionHandler:nil];
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
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    
    [self expectationForNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNotNil(self.controller.error);
        XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotFound);
        XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:@"urn:swi:video:_NO_ID_" standalone:NO];
    
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
    
    [self expectationForNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNotNil(self.controller.error);
        XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
        XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:@"urn:rts:video:playlist500" standalone:NO];
    
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
    
    [self expectationForNotification:SRGLetterboxPlaybackDidFailNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertNotNil(self.controller.error);
        XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotPlayable);
        XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
        XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
        return YES;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self.controller playURN:@"urn:rts:video:onlyHDS" standalone:NO];
    
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
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testRestartLiveOnlyAfterTokenExpiration
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveOnlyVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // The token expires after 30 seconds. Wait a little bit more to be sure it has expired
    [self expectationForElapsedTimeInterval:40. withHandler:nil];

    [self waitForExpectationsWithTimeout:45. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayAfterReset
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player cannot be restarted with a play after a reset. No event expected");
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testTogglePlayPause
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTogglePlayPauseAfterStop
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testTogglePlayPauseAfterReset
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player cannot be restarted with a play after a reset. No event expected");
    }];
    
    [self.controller togglePlayPause];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testPlaybackMetadata
{
    XCTAssertNil(self.controller.URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
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

- (void)testPlaybackMetadataInOnDemandStreamWithSegments
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.mediaComposition.segmentURN);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *segmentURN = OnDemandLongVideoSegmentURN;
    [self.controller switchToURN:segmentURN withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, segmentURN);
    XCTAssertEqualObjects(self.controller.media.URN, segmentURN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.segmentURN, segmentURN);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Seek outside the segment
    [self.controller seekEfficientlyToTime:kCMTimeZero withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.mediaComposition.segmentURN);
}

- (void)testSameMediaPlaybackWhileAlreadyPlaying
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect no change when trying to play the same media
    id metadataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no playback state change when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:metadataObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSameMediaPlaybackWhilePaused
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect only a player state change notification, no metadata change notification
    id metadataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:metadataObserver];
    }];
}

- (void)testOnDemandStreamSkips
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // TTC
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertTrue([self.controller canSkipForward]);

    // Seek to near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    [mediaPlayerController seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
    
    // Seek far enough from the media end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC)) withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertTrue([self.controller canSkipForward]);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeRangeGetEnd(self.controller.timeRange) withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
}

- (void)testLivestreamSkips
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveOnlyVideoURN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
    
    // Cannot skip
    BOOL skipped1 = [self.controller skipBackwardWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    BOOL skipped2 = [self.controller skipForwardWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped2);
}

- (void)testDVRStreamSkips
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveDVRVideoURN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.controller.live);
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
    
    // Seek far enough from live conditions
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC)) withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(self.controller.live);
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertTrue([self.controller canSkipForward]);
    
    // Skip forward again
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekEfficientlyToTime:CMTimeRangeGetEnd(self.controller.timeRange) withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.controller.live);
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
}

- (void)testMultipleSkips
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoURN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Pile up skips forward
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller skipForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertFalse(finished);
    }];
    [self.controller skipForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    
    // Pile up skips backward
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL skipped1 = [self.controller skipBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertFalse(finished);
    }];
    XCTAssertTrue(skipped1);
    
    BOOL skipped2 = [self.controller skipBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    XCTAssertTrue(skipped2);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
}

- (void)testSkipAbilitiesDuringOnDemandStreamPlaybackLifecycle
{
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
    
    __block BOOL preparingReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing) {
            XCTAssertFalse([self.controller canSkipForward]);
            XCTAssertFalse([self.controller canSkipBackward]);
            XCTAssertFalse([self.controller canSkipToLive]);
            
            preparingReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            XCTAssertTrue([self.controller canSkipForward]);
            XCTAssertTrue([self.controller canSkipBackward]);
            XCTAssertFalse([self.controller canSkipToLive]);
            
            playingReceived = YES;
        }
        return preparingReceived && playingReceived;
    }];
    
    [self.controller playURN:OnDemandLongVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekEfficientlyToTime:CMTimeMakeWithSeconds(80., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertTrue([self.controller canSkipForward]);
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
}

- (void)testSkipAbilitiesDuringDVRLivestreamPlaybackLifecycle
{
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
    
    __block BOOL preparingReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing) {
            XCTAssertFalse([self.controller canSkipForward]);
            XCTAssertFalse([self.controller canSkipBackward]);
            XCTAssertFalse([self.controller canSkipToLive]);
            
            preparingReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            XCTAssertFalse([self.controller canSkipForward]);
            XCTAssertTrue([self.controller canSkipBackward]);
            XCTAssertFalse([self.controller canSkipToLive]);
            
            playingReceived = YES;
        }
        return preparingReceived && playingReceived;
    }];
    
    [self.controller playURN:LiveDVRVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekEfficientlyToTime:CMTimeMakeWithSeconds(200., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertTrue([self.controller canSkipForward]);
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertTrue([self.controller canSkipToLive]);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
}

- (void)testSkipAbilitiesDuringLiveOnlyStreamPlaybackLifecycle
{
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
    
    __block BOOL preparingReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing) {
            XCTAssertFalse([self.controller canSkipForward]);
            XCTAssertFalse([self.controller canSkipBackward]);
            XCTAssertFalse([self.controller canSkipToLive]);
            
            preparingReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            XCTAssertFalse([self.controller canSkipForward]);
            XCTAssertFalse([self.controller canSkipBackward]);
            XCTAssertFalse([self.controller canSkipToLive]);
            
            playingReceived = YES;
        }
        return preparingReceived && playingReceived;
    }];
    
    [self.controller playURN:LiveOnlyVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertFalse([self.controller canSkipForward]);
    XCTAssertFalse([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipToLive]);
}

- (void)testSkipToLiveForSwissTXTLimitedDVRStream
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-90];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:500];
    NSString *URN = MMFSwissTXTLimitedDVRURN(startDate, endDate);
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    BOOL skipped1 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeClip)];
    SRGChapter *highlightChapter = [self.controller.mediaComposition.chapters filteredArrayUsingPredicate:predicate].lastObject;
    [self.controller switchToSubdivision:highlightChapter withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, highlightChapter.URN);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL skipped2 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    XCTAssertTrue(skipped2);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
}

- (void)testSkipToLiveForSwissTXTFullDVRStream
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-90];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:500];
    NSString *URN = MMFSwissTXTFullDVRURN(startDate, endDate);
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    
    BOOL skipped1 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekEfficientlyToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL skipped2 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    XCTAssertTrue(skipped2);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
}

- (void)testSkipToLiveForSwissTXTLiveOnlyStream
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-90];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:500];
    NSString *URN = MMFSwissTXTLiveOnlyURN(startDate, endDate);
    
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"No playback state change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL skipped = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSkipToLiveForOnDemandStream
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"No playback state change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL skipped = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSkipToLiveForLivestream
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveOnlyVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"No playback state change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL skipped = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSkipToLiveForDVRStream
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveDVRVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    BOOL skipped1 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeMakeWithSeconds(30., NSEC_PER_SEC) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL skipped2 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    XCTAssertTrue(skipped2);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testPlaybackStateTransitions
{
    BOOL (^expectationHandler)(NSNotification * _Nonnull notification) = ^BOOL(NSNotification * _Nonnull notification) {
        SRGMediaPlayerPlaybackState currentState = [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue];
        SRGMediaPlayerPlaybackState previousState = [notification.userInfo[SRGMediaPlayerPreviousPlaybackStateKey] integerValue];
        XCTAssertTrue(currentState != previousState);
        return YES;
    };
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller prepareToPlayURN:OnDemandVideoURN standalone:NO withCompletionHandler:NULL];
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller play];
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller pause];
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:expectationHandler];
    [self.controller reset];
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testPlaybackStateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.controller keyPath:@"playbackState" expectedValue:@(SRGMediaPlayerPlaybackStatePreparing)];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

 - (void)testContentURLOverriding
{
    NSURL *overridingURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    self.controller.updateInterval = 10.;
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertEqualObjects(self.controller.mediaPlayerController.contentURL, overridingURL);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change with an overriding URL, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Wait for a while. No playback notifications must be received
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change with an overriding URL, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
}

- (void)test360ContentURLOverriding
{
    NSURL *overridingURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    self.controller.updateInterval = 10.;
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.controller.serviceURL];
    [[dataProvider mediaCompositionForURN:OnDemand360VideoURN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        media = mediaComposition.fullLengthMedia;
        
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playMedia:media standalone:NO];
    
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
    NSURL *overridingURL = [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    self.controller.updateInterval = 10.;
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return overridingURL;
    };
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoURN atTime:CMTimeMakeWithSeconds(15., NSEC_PER_SEC) standalone:NO withPreferredStreamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:SRGLetterboxDefaultStartBitRate];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqual(CMTimeGetSeconds(self.controller.currentTime), 15.);
}

- (void)testUninterruptedOnDemandFullLengthPlayback
{
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a full length, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a full length, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
}

- (void)testUninterruptedOnDemandSegmentPlayback
{
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:URN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNotEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainSegment.URN, URN);
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when playing a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
}

- (void)testUninterruptedOnDemandPlaybackAfterSegmentSelection
{
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    [self.controller switchToSubdivision:self.controller.mediaComposition.mainChapter.segments[2] withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Play for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when selecting a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when selecting a segment, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
}

- (void)testUninterruptedLivePlayback
{
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = LiveOnlyVideoURN;
    [self.controller playURN:URN standalone:NO];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.mainChapter.URN, URN);
    
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a stop from the user.");
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when stoping playback, even if there is a channel or controller update.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
}

- (void)testMediaNotYetAvailable
{
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    // Media starts in 7 seconds and is available 7 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonStartDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotAvailable);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxTimeAvailabilityKey] integerValue], SRGTimeAvailabilityNotYetAvailable);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeNotAvailable);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxTimeAvailabilityKey] integerValue], SRGTimeAvailabilityNotAvailableAnymore);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    // Attempt to play again and wait for a while. No playback notifications must be received
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
}

- (void)testMediaAvailable
{
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:15];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testMediaNotAvailableAnymore
{
    self.controller.serviceURL = MMFServiceURL();
    
    // Wait for a while. No playback notifications must be received
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available anymore.");
    }];
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not available anymore On Demand media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);

    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-15];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testMediaAvailableWithServerCacheInconsistency
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media started 1 second before and is available 20 seconds, but the server doesn't remove the blocking reason
    // STARTDATE on time.
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-1];
    NSDate *endDate = [startDate dateByAddingTimeInterval:20];
    NSString *URN = MMFCachedScheduledOnDemandVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonStartDate);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMediaComposition *mediaComposition = notification.userInfo[SRGLetterboxMediaCompositionKey];
        return mediaComposition && [mediaComposition.mainChapter blockingReasonAtDate:[NSDate date]] == SRGBlockingReasonNone;
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];

    // Media starts playing after a metadata udpate

    [self waitForExpectationsWithTimeout:30. handler:nil];

    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
}

- (void)testMediaWithOverriddenURLNotYetAvailable
{
    self.controller.serviceURL = MMFServiceURL();
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    };
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFScheduledOnDemandVideoURN(startDate, endDate);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeeded"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:self.controller.serviceURL];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        media = mediaComposition.fullLengthMedia;
        
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Wait for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller playMedia:media standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonStartDate);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason has been received.");
    }];
    
    // Attempt to play again and wait for a while. No playback notifications must be received since the media is not
    // available anymore
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
    }];
}

- (void)testResourceChangedWhenPlaying
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFURLChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // A URL change occurs.
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNil(self.controller.mediaPlayerController.contentURL);
    
    // Playback must not restart automatically. Wait for a while to ensure no playback notifications are received anymore.
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change anymore after URL change.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testResourceChangedWhenPaused
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFURLChangeVideoURN(startDate, endDate);
    [self.controller prepareToPlayURN:URN standalone:NO withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
        
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // A URL change occurs.
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNil(self.controller.mediaPlayerController.contentURL);
    
    // Playback must not restart automatically. Wait for a while to ensure no playback notifications are received anymore.
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change anymore after URL change.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testResourceChangedWhenStopped
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFURLChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    
    NSURL *firstURL = self.controller.mediaPlayerController.contentURL;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // URL changes while idle must not lead to playback state changes.
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when stopped.");
    }];
    
    [self expectationForElapsedTimeInterval:12. withHandler:nil];
    
    // A URL change occurs while the player is idle.
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNil(self.controller.mediaPlayerController.contentURL);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertNotEqualObjects(self.controller.mediaPlayerController.contentURL, firstURL);
}

- (void)testBlockingReasonAppeared
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:60];
    NSString *URN = MMFBlockingReasonChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    
    // A blocking reason appearing while playing must stop playback
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    // A blocking reason appears.
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonGeoblocking);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeBlocked);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonGeoblocking);
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testBlockingReasonDisappearance
{
    self.controller.serviceURL = MMFServiceURL();
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-5];
    NSDate *endDate = [startDate dateByAddingTimeInterval:10];
    NSString *URN = MMFBlockingReasonChangeVideoURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonGeoblocking);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    XCTAssertEqual(self.controller.error.code, SRGLetterboxErrorCodeBlocked);
    XCTAssertEqual([self.controller.error.userInfo[SRGLetterboxBlockingReasonKey] integerValue], SRGBlockingReasonGeoblocking);
    
    // The blocking reason disappears
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPeriodicUpdatesForLivestream
{
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveOnlyVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    // An update must occur automatically
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPeriodicUpdatesForOnDemandStream
{
    self.controller.updateInterval = 10.;
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    // An update must occur automatically
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testSwissTXTFullDVRNotYetAvailable
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not yet available live media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media starts in 7 seconds and is available 7 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFSwissTXTFullDVRURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNotNil(self.controller.error);
    
    // Wait the new media composition a few seconds
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeEpisode);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNotEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual(self.controller.media.contentType, SRGContentTypeEpisode);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testSwissTXTLimitedDVRNotYetAvailable
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not yet available live media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media starts in 7 seconds and is available 15 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:15];
    NSString *URN = MMFSwissTXTLimitedDVRURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    XCTAssertNotNil(self.controller.error);
    
    // Attempt to play again and wait for a while. No playback notifications must be received
    id eventObserver3 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver3];
    }];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeClip)];
    NSArray <SRGChapter *> *highlightChapters = [self.controller.mediaComposition.chapters filteredArrayUsingPredicate:predicate];
    XCTAssertNotEqual(highlightChapters.count, 0);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqual(self.controller.media.contentType, SRGContentTypeClip);
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToSubdivision:highlightChapters.firstObject withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testSwissTXTLiveOnlyNotYetAvailable
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not yet available live media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media starts in 7 seconds and is available 7 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFSwissTXTLiveOnlyURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNotNil(self.controller.error);
    
    // Attempt to play again and wait for a while. No playback notifications must be received
    id eventObserver3 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver3];
    }];
}

- (void)testSwissTXTLiveOnlyNotAvailableAnymore
{
    self.controller.serviceURL = MMFServiceURL();
    
    // Wait for a while. No playback notifications must be received
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available anymore.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self expectationForNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media started 10 seconds before and is available 5 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-10];
    NSDate *endDate = [startDate dateByAddingTimeInterval:5];
    NSString *URN = MMFSwissTXTLiveOnlyURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

- (void)testSwissTXTFullDVRWithHighlightRemoved
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media started 16 seconds ago and is available 40 seconds // Second higlight will be removed
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-16];
    NSDate *endDate = [startDate dateByAddingTimeInterval:40];
    NSString *URN = MMFSwissTXTFullDVRURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 3);
    
    SRGSegment *secondHighlightSegment = self.controller.mediaComposition.mainChapter.segments[1];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    // Switch to second highlight
    
    [self.controller switchToSubdivision:secondHighlightSegment withCompletionHandler:^(BOOL finished) {
        [self.controller pause];
    }];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, secondHighlightSegment.URN);
    XCTAssertEqualObjects(self.controller.media.URN, secondHighlightSegment.URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertTrue([self.controller.mediaComposition.mainChapter.segments containsObject:secondHighlightSegment]);
    
    id eventStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No playback state change is expected");
    }];
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([self.controller.mediaComposition.mainChapter.segments containsObject:secondHighlightSegment]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventStateObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertFalse([self.controller.mediaComposition.mainChapter.segments containsObject:secondHighlightSegment]);
    XCTAssertNotEqual(self.controller.mediaComposition.mainChapter.segments.count, 3);
}

- (void)testSwissTXTLimitedDVRWithHighlightRemoved
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Media started 16 seconds ago and is available 28 seconds. Second higlight will be removed
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-16];
    NSDate *endDate = [startDate dateByAddingTimeInterval:28];
    NSString *URN = MMFSwissTXTLimitedDVRURN(startDate, endDate);
    [self.controller playURN:URN standalone:NO];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 4);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeClip)];
    NSArray <SRGChapter *> *highlightChapters = [self.controller.mediaComposition.chapters filteredArrayUsingPredicate:predicate];
    XCTAssertNotEqual(highlightChapters.count, 0);
    
    SRGChapter *secondHighlightChapter = highlightChapters[1];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    // Switch to second highlight
    
    [self.controller switchToSubdivision:secondHighlightChapter withCompletionHandler:^(BOOL finished) {
        [self.controller pause];
    }];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, secondHighlightChapter.URN);
    XCTAssertEqualObjects(self.controller.media.URN, secondHighlightChapter.URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertTrue([self.controller.mediaComposition.chapters containsObject:secondHighlightChapter]);
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([self.controller.mediaComposition.chapters containsObject:secondHighlightChapter]);
        return YES;
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:nil];
    
    // Media stops playing because of a kill switch to the full length media
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertFalse([self.controller.mediaComposition.chapters containsObject:secondHighlightChapter]);
    XCTAssertNotEqual(self.controller.mediaComposition.chapters.count, 4);
}

- (void)testSwissTXTLimitedDVRPlayHighlightAfterLivestreamEnd
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-1000.];
    NSDate *endDate = [startDate dateByAddingTimeInterval:-30.];
    NSString *URN = [MMFSwissTXTLimitedDVRURN(startDate, endDate) stringByAppendingString:@"_segment1"];
    [self.controller prepareToPlayURN:URN standalone:NO withCompletionHandler:nil];
    
    id livestreamEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No livestream end notification expected");
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:livestreamEndObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeClip);
    XCTAssertNil(self.controller.error);
}

- (void)testSwitchToSegmentURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoSegmentURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.controller.mediaPlayerController handler:nil];
    
    NSArray<SRGSegment *> *segments = self.controller.mediaComposition.mainChapter.segments;
    XCTAssertTrue(segments.count >= 3);
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:segments[2].URN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testSwitchToChapterURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoSegmentURN standalone:YES];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    __block BOOL idleReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle) {
            idleReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            playingReceived = YES;
        }
        return idleReceived && playingReceived;
    }];
    
    id segmentStartObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerSegmentDidStartNotification object:self.controller.mediaPlayerController queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No segment transition is expected");
    }];
    
    NSArray<SRGChapter *> *chapters = self.controller.mediaComposition.chapters;
    XCTAssertTrue(chapters.count >= 3);
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:chapters[2].URN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:segmentStartObserver];
    }];
}

- (void)testSwitchToUnrelatedURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoSegmentURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Other media composition retrieval"];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No playback state change is expected");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL switched = [self.controller switchToURN:fetchedMediaComposition.mainChapter.URN withCompletionHandler:^(BOOL finished) {
        XCTFail(@"The completion handler must only be called when switching occurs");
    }];
    XCTAssertFalse(switched);
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventStateObserver];
    }];
}

- (void)testSwitchToSameSegmentURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerSegmentDidEndNotification object:self.controller.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] URN], URN);
        return YES;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.controller.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] URN], URN);
        return YES;
    }];
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:URN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testSwitchToSameChapterURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    __block BOOL idleReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle) {
            idleReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            playingReceived = YES;
        }
        return idleReceived && playingReceived;
    }];
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:URN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testSwitchToSegmentURNWhilePreparing
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:OnDemandLongVideoSegmentURN standalone:NO];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGMediaPlayerSegmentDidStartNotification object:self.controller.mediaPlayerController handler:nil];
    
    NSArray<SRGSegment *> *segments = self.controller.mediaComposition.mainChapter.segments;
    XCTAssertTrue(segments.count >= 3);
    
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:segments[2].URN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertFalse(self.controller.loading);
}

- (void)testSwitchToChapterURNWhilePreparing
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:OnDemandAudioWithChaptersURN standalone:NO];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    
    NSMutableArray<SRGChapter *> *chapters = self.controller.mediaComposition.chapters.mutableCopy;
    [chapters removeObject:self.controller.mediaComposition.mainChapter];
    SRGChapter *chapter = chapters.firstObject;
    XCTAssertNotNil(chapter);

    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:chapter.URN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertFalse(self.controller.loading);
}

- (void)testSwitchToBlockedChapterURNWhilePreparing
{
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:MMFOnDemandLongVideoURN standalone:YES];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGLetterboxURNKey] isEqual:MMFOnDemandLongVideoGeoblockSegmentURN];
    }];
    
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    
    BOOL switched = [self.controller switchToURN:MMFOnDemandLongVideoGeoblockSegmentURN withCompletionHandler:^(BOOL finished) {
        XCTFail(@"Completion handler must not be called");
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:[NSDate date]], SRGBlockingReasonGeoblocking);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertFalse(self.controller.loading);
}

- (void)testSocialCountViewPlayOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayPauseOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayStopQuicklyOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send Social count views after a stop. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSocialCountViewPlayStopOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller restart];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    // With the current "lack of specification", we expect to have a second social count view
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPrepareToPlay
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller prepareToPlayURN:URN standalone:NO withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send Social count views when only prepared. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    // After playback has started we expect a social view count increase
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayResetOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send Social count views after a reset. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSocialCountViewPlayPausePlayOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send the same social count view twice. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSocialCountViewPlayOnSegment
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    NSString *segmentURN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:segmentURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayChangePlayOnChapter
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN1 = OnDemandVideoURN;
    [self.controller playURN:URN1 standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN2 = OnDemandLongVideoURN;
    [self.controller playURN:URN2 standalone:NO];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN2);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewSwitchToChapterURN
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:URN standalone:YES];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    __block BOOL idleReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle) {
            idleReceived = YES;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            playingReceived = YES;
        }
        return idleReceived && playingReceived;
    }];
    
    NSArray<SRGChapter *> *chapters = self.controller.mediaComposition.chapters;
    XCTAssertTrue(chapters.count >= 3);
    
    NSString *switchURN = chapters[2].URN;
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler"];
    BOOL switched = [self.controller switchToURN:switchURN withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
        [completionHandlerExpectation fulfill];
    }];
    XCTAssertTrue(switched);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, switchURN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testLoadingWhileSeeking
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:LiveDVRVideoURN standalone:NO];
    
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(self.controller.loading);
    
    // Seek far enough from live conditions
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking) {
            XCTAssertTrue(self.controller.loading);
            return NO;
        }
        else if ([notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying) {
            XCTAssertFalse(self.controller.loading);
            return YES;
        }
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC)) withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(self.controller.loading);
}

- (void)testLoadingKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.controller keyPath:@"loading" expectedValue:@YES];
    
    [self.controller playURN:LiveDVRVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.controller keyPath:@"loading" expectedValue:@NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testMetadataUpdatesAfterStop
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.controller.updateInterval = 10.;
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMetadataUpdatesAfterReset
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.controller.updateInterval = 10.;
    [self.controller playURN:OnDemandVideoURN standalone:NO];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No metadata updates must be received after a reset");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

@end
