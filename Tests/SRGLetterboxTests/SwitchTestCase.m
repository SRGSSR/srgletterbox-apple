//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"
#import "TrackerSingletonSetup.h"

@import SRGDataProviderNetwork;
@import SRGLetterbox;

@interface SwitchTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation SwitchTestCase

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

- (void)testSwitchToSegmentURN
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoSegmentURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    [self expectationForSingleNotification:SRGLetterboxSegmentDidStartNotification object:self.controller handler:nil];
    
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
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = YES;
    
    [self.controller playURN:OnDemandLongVideoSegmentURN atPosition:nil withPreferredSettings:settings];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    __block BOOL idleReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:OnDemandLongVideoSegmentURN atPosition:nil withPreferredSettings:nil];
    
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
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSegmentDidEndNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        XCTAssertEqualObjects([notification.userInfo[SRGMediaPlayerSegmentKey] URN], URN);
        return YES;
    }];
    [self expectationForSingleNotification:SRGLetterboxSegmentDidStartNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    __block BOOL idleReceived = NO;
    __block BOOL playingReceived = NO;
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:OnDemandLongVideoSegmentURN atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    [self expectationForSingleNotification:SRGLetterboxSegmentDidStartNotification object:self.controller handler:nil];
    
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
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    [self.controller playURN:OnDemandAudioWithChaptersURN atPosition:nil withPreferredSettings:nil];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
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
    self.controller.globalParameters = @{ @"forceLocation" : @"WW" };
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityNone);
    XCTAssertFalse(self.controller.loading);
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = YES;
    
    [self.controller playURN:OnDemandLongVideo2URN atPosition:nil withPreferredSettings:settings];
    
    XCTAssertEqual(self.controller.dataAvailability, SRGLetterboxDataAvailabilityLoading);
    XCTAssertTrue(self.controller.loading);
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGLetterboxURNKey] isEqual:OnDemandLongVideo2GeoblockedSegmentURN];
    }];
    
    XCTAssertTrue(self.controller.mediaComposition.chapters.count > 1);
    
    BOOL switched = [self.controller switchToURN:OnDemandLongVideo2GeoblockedSegmentURN withCompletionHandler:^(BOOL finished) {
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
