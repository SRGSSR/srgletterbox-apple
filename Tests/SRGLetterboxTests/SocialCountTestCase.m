//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

@import SRGLetterbox;

// Imports required to test internals
#import "SRGLetterboxController+Private.h"

@interface SocialCountTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation SocialCountTestCase

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

- (void)testSocialCountViewPlayOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayPauseOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayStopQuicklyOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send Social count views after a stop. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSocialCountViewPlayStopOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller restart];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    // With the current "lack of specification", we expect to have a second social count view
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPrepareToPlay
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller prepareToPlayURN:URN atPosition:nil withPreferredSettings:nil completionHandler:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send Social count views when only prepared. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    // After playback has started we expect a social view count increase
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayResetOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send Social count views after a reset. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSocialCountViewPlayPausePlayOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePaused;
    }];
    
    [self.controller pause];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller play];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not send the same social count view twice. No event expected");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testSocialCountViewPlayOnSegment
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    NSString *segmentURN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:segmentURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewPlayChangePlayOnChapter
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN1 = OnDemandVideoURN;
    [self.controller playURN:URN1 atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN2 = OnDemandLongVideoURN;
    [self.controller playURN:URN2 atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN2);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

- (void)testSocialCountViewSwitchToChapterURN
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = YES;
    
    NSString *URN = OnDemandLongVideoSegmentURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:settings];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, URN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
    
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
    
    [self expectationForSingleNotification:SRGLetterboxSocialCountViewWillIncreaseNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGSubdivision *subdivision = notification.userInfo[SRGLetterboxSubdivisionKey];
        XCTAssertEqualObjects(subdivision.URN, switchURN);
        return YES;
    }];
    
    [self waitForExpectationsWithTimeout:15. handler:nil];
}

@end
