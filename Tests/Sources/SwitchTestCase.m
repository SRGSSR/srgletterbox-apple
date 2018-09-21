//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface SwitchTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation SwitchTestCase

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
    [self expectationForNotification:SRGLetterboxSegmentDidStartNotification object:self.controller handler:nil];
    
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
    
    id segmentStartObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxSegmentDidStartNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
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
        [NSNotificationCenter.defaultCenter removeObserver:segmentStartObserver];
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
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventStateObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No playback state change is expected");
    }];
    
    [self expectationForElapsedTimeInterval:4. withHandler:nil];
    
    BOOL switched = [self.controller switchToURN:fetchedMediaComposition.mainChapter.URN withCompletionHandler:^(BOOL finished) {
        XCTFail(@"The completion handler must only be called when switching occurs");
    }];
    XCTAssertFalse(switched);
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventStateObserver];
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
    
    [self expectationForNotification:SRGLetterboxSegmentDidEndNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] URN], URN);
        return YES;
    }];
    [self expectationForNotification:SRGLetterboxSegmentDidStartNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForNotification:SRGLetterboxSegmentDidStartNotification object:self.controller handler:nil];
    
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
    XCTAssertEqual([self.controller.media blockingReasonAtDate:NSDate.date], SRGBlockingReasonGeoblocking);
    XCTAssertNotNil(self.controller.error);
    XCTAssertEqualObjects(self.controller.error.domain, SRGLetterboxErrorDomain);
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoaded);
    XCTAssertFalse(self.controller.loading);
}

@end
