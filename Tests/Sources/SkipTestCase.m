//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface SkipTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation SkipTestCase

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

- (void)testOnDemandStreamSkips
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // TTC
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertTrue([self.controller canSkipForward]);
    
    // Seek to near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    CMTime seekTime = CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(15., NSEC_PER_SEC));
    [self.controller seekToPosition:[SRGPosition positionAtTime:seekTime] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
    
    // Seek far enough from the media end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    CMTime seekTime1 = CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC));
    [self.controller seekToPosition:[SRGPosition positionAtTime:seekTime1] withCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertTrue([self.controller canSkipForward]);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    CMTime seekTime2 = CMTimeRangeGetEnd(self.controller.timeRange);
    [self.controller seekToPosition:[SRGPosition positionAtTime:seekTime2] withCompletionHandler:^(BOOL finished) {
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
    
    [self.controller playURN:LiveOnlyVideoURN atPosition:nil withPreferredSettings:nil];
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
    
    [self.controller playURN:LiveDVRVideoURN atPosition:nil withPreferredSettings:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertTrue(self.controller.live);
    
    XCTAssertTrue([self.controller canSkipBackward]);
    XCTAssertFalse([self.controller canSkipForward]);
    
    // Seek far enough from live conditions
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    CMTime seekTime1 = CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(60., NSEC_PER_SEC));
    [self.controller seekToPosition:[SRGPosition positionAtTime:seekTime1] withCompletionHandler:^(BOOL finished) {
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
    
    CMTime seekTime2 = CMTimeRangeGetEnd(self.controller.timeRange);
    [self.controller seekToPosition:[SRGPosition positionAroundTime:seekTime2] withCompletionHandler:^(BOOL finished) {
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
    
    [self.controller playURN:OnDemandLongVideoURN atPosition:nil withPreferredSettings:nil];
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
    
    [self.controller playURN:OnDemandLongVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekToPosition:[SRGPosition positionAroundTimeInSeconds:80.] withCompletionHandler:nil];
    
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
    
    [self.controller playURN:LiveDVRVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekToPosition:[SRGPosition positionAroundTimeInSeconds:200.] withCompletionHandler:nil];
    
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
    
    [self.controller playURN:LiveOnlyVideoURN atPosition:nil withPreferredSettings:nil];
    
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

- (void)testSkipToLiveForOnDemandStream
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"No playback state change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL skipped = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSkipToLiveForLivestream
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveOnlyVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"No playback state change must occur");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL skipped = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSkipToLiveForDVRStream
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:LiveDVRVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    BOOL skipped1 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekToPosition:[SRGPosition positionAtTimeInSeconds:30.] withCompletionHandler:nil];
    
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

@end
