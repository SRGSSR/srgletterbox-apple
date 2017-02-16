//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <XCTest/XCTest.h>

// Test internals
#import "SRGLetterboxController+Private.h"

@interface LetterboxControllerTestCase : XCTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation LetterboxControllerTestCase

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

- (void)testShortLifetime
{
    __unused SRGLetterboxController *letterboxController = [[SRGLetterboxController alloc] init];
}

- (void)testPlayURN
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing, at which time we expect the media composition to be available
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
    [self.controller playURN:URN];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.error);
}

- (void)testPlayMedia
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media retrieved"];
    
    __block SRGMedia *media = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerTestServiceURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videosWithUids:@[@"42844052"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        media = medias.firstObject;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNotNil(media);
    
    // Wait until the stream is playing, at which time we expect the media composition to be available
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    [self.controller playMedia:media];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Media information must now be available
    XCTAssertEqualObjects(self.controller.URN, media.URN);
    XCTAssertEqualObjects(self.controller.media, media);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, media.URN);
    XCTAssertNil(self.controller.error);
}

- (void)testReset
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
    [self.controller playURN:URN];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    XCTAssertNil(self.controller.URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlaybackMetadata
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    XCTAssertNil(self.controller.URN);
    XCTAssertNil(self.controller.media);
    XCTAssertNil(self.controller.mediaComposition);
    XCTAssertNil(self.controller.error);
    
    // Wait until the stream is playing, at which time we expect the media composition to be available
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
    [self.controller playURN:URN];
    
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

- (void)testSameMediaPlaybackWhileAlreadyPlaying
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect no change when trying to play the same media
    id metadataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no playback state change when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"]];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:metadataObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

- (void)testSameMediaPlaybackWhilePaused
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"]];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Pause playback
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [mediaPlayerController pause];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // Expect only a player state change notification, no metadata change notification
    id metadataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"Expect no metadata update when playing the same media");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"]];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:metadataObserver];
    }];
}

- (void)testOnDemandStreamSeeks
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // TTC
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rts:video:8297891"]];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertTrue([self.controller canSeekForward]);

    // Seek to near the end
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [mediaPlayerController seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(mediaPlayerController.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
    
    // Use standard seeks
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertTrue([self.controller canSeekForward]);
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
}

- (void)testLiveStreamSeeks
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rsi:video:livestream_La1"]];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
    
    // Cannot seek
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertFalse(finished);
    }];
    [self.controller seekForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertFalse(finished);
    }];
}

- (void)testDVRStreamSeeks
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rts:video:1967124"]];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(mediaPlayerController.live);
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
    
    // Seek in the past
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(mediaPlayerController.live);
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertTrue([self.controller canSeekForward]);
    
    // Seek forward again
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(mediaPlayerController.live);
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
}

- (void)testMultipleSeeks
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rts:video:8297891"]];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Pile up seeks forwards
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertFalse(finished);
    }];
    [self.controller seekForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    
    // Pile up seeks backwards
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertFalse(finished);
    }];
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
}

@end
