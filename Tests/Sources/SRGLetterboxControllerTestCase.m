//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>
#import <XCTest/XCTest.h>

static NSURL *OnDemandTestURL(void)
{
    return [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
}

static NSURL *LiveTestURL(void)
{
    return [NSURL URLWithString:@"http://fr-par-iphone-2.cdn.hexaglobe.net/streaming/euronews_ewns/9-live.m3u8"];
}

static NSURL *DVRTestURL(void)
{
    return [NSURL URLWithString:@"https://wowza.jwplayer.com/live/jelly.stream/playlist.m3u8?DVR"];
}

@interface SRGLetterboxControllerTestCase : XCTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation SRGLetterboxControllerTestCase

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

- (void)testOnDemandStreamSeeks
{
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertTrue([self.controller canSeekForward]);

    // Seek to near the end
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC)) withCompletionHandler:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
    
    // Use standard seeks
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertTrue([self.controller canSeekForward]);
    
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURL:LiveTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
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
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURL:DVRTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.controller.live);
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
    
    // Seek in the past
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekBackwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertFalse(self.controller.live);
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertTrue([self.controller canSeekForward]);
    
    // Seek forward again
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekForwardWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.controller.live);
    
    XCTAssertTrue([self.controller canSeekBackward]);
    XCTAssertFalse([self.controller canSeekForward]);
}

- (void)testMultipleSeeks
{
    // Wait until the stream is playing
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Pile up seeks forwards
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
