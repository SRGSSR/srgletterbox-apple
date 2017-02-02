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

#pragma mark Setup and teardown

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

- (void)testPlayURN
{

}

- (void)testPlayMedia
{

}

- (void)testReset
{

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
    [self.controller playURN:URN withPreferredQuality:SRGQualityNone];
    
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

- (void)testOnDemandStreamSeeks
{
    SRGMediaPlayerController *mediaPlayerController = self.controller.mediaPlayerController;
    
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // TTC
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rts:video:8297891"] withPreferredQuality:SRGQualityNone];
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
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rsi:video:livestream_La1"] withPreferredQuality:SRGQualityNone];
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
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rts:video:1967124"] withPreferredQuality:SRGQualityNone];
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
    
    [self.controller playURN:[SRGMediaURN mediaURNWithString:@"urn:rts:video:8297891"] withPreferredQuality:SRGQualityNone];
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
