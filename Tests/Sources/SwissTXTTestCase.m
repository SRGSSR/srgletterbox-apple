//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>

// Imports required to test internals
#import "SRGLetterboxController+Private.h"

@interface SwissTXTTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation SwissTXTTestCase

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

- (void)testSkipToLiveForSwissTXTLimitedDVRStream
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-90];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:500];
    NSString *URN = MMFSwissTXTLimitedDVRURN(startDate, endDate);
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    BOOL skipped1 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeClip)];
    SRGChapter *highlightChapter = [self.controller.mediaComposition.chapters filteredArrayUsingPredicate:predicate].lastObject;
    [self.controller switchToSubdivision:highlightChapter withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, highlightChapter.URN);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL skipped2 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTAssertTrue(finished);
    }];
    XCTAssertTrue(skipped2);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
}

// TODO: #166 Test is flaky and can make further tests fail afterwards. Should be improved
- (void)testSkipToLiveForSwissTXTFullDVRStream
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-90];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:500];
    NSString *URN = MMFSwissTXTFullDVRURN(startDate, endDate);
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    
    BOOL skipped1 = [self.controller skipToLiveWithCompletionHandler:^(BOOL finished) {
        XCTFail(@"Must not be called");
    }];
    XCTAssertFalse(skipped1);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller seekToPosition:[SRGPosition positionAroundTimeInSeconds:30.] withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-90];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:500];
    NSString *URN = MMFSwissTXTLiveOnlyURN(startDate, endDate);
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
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

// TODO: #166 Test is flaky and can make further tests fail afterwards. Should be improved
- (void)testSwissTXTFullDVRNotYetAvailable
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Waiting for a while. No playback notifications must be received
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not yet available live media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media starts in 7 seconds and is available 7 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFSwissTXTFullDVRURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForSingleNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNotNil(self.controller.error);
    
    // Wait the new media composition a few seconds
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeEpisode);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNotEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not yet available live media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media starts in 7 seconds and is available 15 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:15];
    NSString *URN = MMFSwissTXTLimitedDVRURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForSingleNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    XCTAssertNotNil(self.controller.error);
    
    // Attempt to play again and wait for a while. No playback notifications must be received
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeClip)];
    NSArray <SRGChapter *> *highlightChapters = [self.controller.mediaComposition.chapters filteredArrayUsingPredicate:predicate];
    XCTAssertNotEqual(highlightChapters.count, 0);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    id eventObserver1 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available yet.");
    }];
    id eventObserver2 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Livestream did finish notification must not fire for a not yet available live media.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    // Media starts in 7 seconds and is available 7 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:7];
    NSDate *endDate = [startDate dateByAddingTimeInterval:7];
    NSString *URN = MMFSwissTXTLiveOnlyURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver1];
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonStartDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNotNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media starts playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNil(self.controller.error);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    [self expectationForSingleNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media stops playing
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 0);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 1);
    XCTAssertNotNil(self.controller.error);
    
    // Attempt to play again and wait for a while. No playback notifications must be received
    id eventObserver3 = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when a block reason is here.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver3];
    }];
}

- (void)testSwissTXTLiveOnlyNotAvailableAnymore
{
    self.controller.serviceURL = MMFServiceURL();
    
    // Wait for a while. No playback notifications must be received
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        XCTFail(@"Playback state must not change when media is not available anymore.");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    
    [self expectationForSingleNotification:SRGLetterboxLivestreamDidFinishNotification object:self.controller handler:nil];
    
    // Media started 10 seconds before and is available 5 seconds
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-10];
    NSDate *endDate = [startDate dateByAddingTimeInterval:5];
    NSString *URN = MMFSwissTXTLiveOnlyURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonEndDate);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
}

// TODO: #166 Test is flaky and can make further tests fail afterwards. Should be improved.
- (void)testSwissTXTFullDVRWithHighlightRemoved
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Media started 16 seconds ago and is available 40 seconds. Second higlight will be removed
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-16];
    NSDate *endDate = [startDate dateByAddingTimeInterval:40];
    NSString *URN = MMFSwissTXTFullDVRURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.mediaComposition.mainChapter.segments.count, 3);
    
    SRGSegment *secondHighlightSegment = self.controller.mediaComposition.mainChapter.segments[1];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    // Switch to second highlight
    
    [self.controller switchToSubdivision:secondHighlightSegment withCompletionHandler:^(BOOL finished) {
        XCTAssertEqual(self.controller.mediaPlayerController.streamType, SRGStreamTypeDVR);
        [self.controller pause];
    }];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, secondHighlightSegment.URN);
    XCTAssertEqualObjects(self.controller.media.URN, secondHighlightSegment.URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertTrue([self.controller.mediaComposition.mainChapter.segments containsObject:secondHighlightSegment]);
    
    id eventStateObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No playback state change is expected");
    }];
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([self.controller.mediaComposition.mainChapter.segments containsObject:secondHighlightSegment]);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventStateObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertFalse([self.controller.mediaComposition.mainChapter.segments containsObject:secondHighlightSegment]);
    XCTAssertNotEqual(self.controller.mediaComposition.mainChapter.segments.count, 3);
}

// TODO: #166 Test is flaky and can make further tests fail afterwards. Should be improved
- (void)testSwissTXTLimitedDVRWithHighlightRemoved
{
    self.controller.updateInterval = 10.;
    self.controller.serviceURL = MMFServiceURL();
    
    // Media started 16 seconds ago and is available 28 seconds. Second higlight will be removed
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-16];
    NSDate *endDate = [startDate dateByAddingTimeInterval:28];
    NSString *URN = MMFSwissTXTLimitedDVRURN(startDate, endDate);
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeScheduledLivestream);
    XCTAssertNil(self.controller.error);
    XCTAssertEqual(self.controller.mediaComposition.chapters.count, 4);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeClip)];
    NSArray <SRGChapter *> *highlightChapters = [self.controller.mediaComposition.chapters filteredArrayUsingPredicate:predicate];
    XCTAssertNotEqual(highlightChapters.count, 0);
    
    SRGChapter *secondHighlightChapter = highlightChapters[1];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    // Switch to second highlight
    
    [self.controller switchToSubdivision:secondHighlightChapter withCompletionHandler:^(BOOL finished) {
        XCTAssertEqual(self.controller.mediaPlayerController.streamType, SRGStreamTypeLive);
        [self.controller pause];
    }];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, secondHighlightChapter.URN);
    XCTAssertEqualObjects(self.controller.media.URN, secondHighlightChapter.URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertNil(self.controller.error);
    XCTAssertTrue([self.controller.mediaComposition.chapters containsObject:secondHighlightChapter]);
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertFalse([self.controller.mediaComposition.chapters containsObject:secondHighlightChapter]);
        return YES;
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:nil];
    
    // Media stops playing because of a kill switch to the full length media
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStateIdle);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
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
    [self.controller prepareToPlayURN:URN atPosition:nil withPreferredSettings:nil completionHandler:nil];
    
    id livestreamEndObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxLivestreamDidFinishNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No livestream end notification expected");
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:livestreamEndObserver];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqual(self.controller.playbackState, SRGMediaPlayerPlaybackStatePaused);
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonNone);
    XCTAssertEqual(self.controller.media.contentType, SRGContentTypeClip);
    XCTAssertNil(self.controller.error);
}

@end
