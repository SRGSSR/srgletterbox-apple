//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

@import libextobjc;
@import SRGLetterbox;

// Imports required to test internals
#import "SRGLetterboxController+Private.h"

@interface MetadataTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation MetadataTestCase

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

- (void)testPlaybackMetadataInOnDemandStreamWithSegments
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandLongVideoURN;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.mediaComposition.segmentURN);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *segmentURN = OnDemandLongVideoSegmentURN;
    [self.controller switchToURN:segmentURN withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, segmentURN);
    XCTAssertEqualObjects(self.controller.media.URN, segmentURN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.segmentURN, segmentURN);
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    // Seek outside the segment
    [self.controller seekToPosition:nil withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, URN);
    XCTAssertEqualObjects(self.controller.media.URN, URN);
    XCTAssertEqualObjects(self.controller.mediaComposition.chapterURN, URN);
    XCTAssertNil(self.controller.mediaComposition.segmentURN);
}

- (void)testMetadataUpdatesAfterStop
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.controller.updateInterval = 10.;
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller stop];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxMetadataDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return notification.userInfo[SRGLetterboxMediaCompositionKey] != nil;
    }];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMetadataUpdatesAfterReset
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.controller.updateInterval = 10.;
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateIdle;
    }];
    
    [self.controller reset];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGLetterboxMetadataDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No metadata updates must be received after a reset");
    }];
    
    [self expectationForElapsedTimeInterval:15. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
}

- (void)testDisplayableSubdivisionAtTime
{
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    NSString *URN = OnDemandVideoWithLegalBlockedContentURN;
    
    self.controller.updateInterval = 10.;
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects([self.controller displayableSubdivisionAtTime:kCMTimeZero].URN, URN);
    
    SRGSegment *firstSegment = self.controller.mediaComposition.mainChapter.segments.firstObject;
    XCTAssertNotNil(firstSegment);
    XCTAssertFalse(firstSegment.hidden);
    
    CMTime segmentTime = CMTimeMakeWithSeconds((firstSegment.markIn + firstSegment.duration / 2.) / 1000., NSEC_PER_SEC);
    XCTAssertEqualObjects([self.controller displayableSubdivisionAtTime:segmentTime].URN, firstSegment.URN);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGSegment.new, URN), OnDemandVideoWithLegalBlockedContentSegementURN];
    SRGSegment *legalBlockedSegment = [self.controller.mediaComposition.mainChapter.segments filteredArrayUsingPredicate:predicate].firstObject;
    XCTAssertNotNil(legalBlockedSegment);
    XCTAssertTrue(legalBlockedSegment.hidden);
    
    CMTime hiddenTime = CMTimeMakeWithSeconds((legalBlockedSegment.markIn + legalBlockedSegment.duration / 2.) / 1000., NSEC_PER_SEC);
    XCTAssertEqualObjects([self.controller displayableSubdivisionAtTime:hiddenTime].URN, URN);

    [self.controller reset];
    
    [self expectationForSingleNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    self.controller.contentURLOverridingBlock = ^NSURL * _Nullable(NSString * _Nonnull URN) {
        return [NSURL URLWithString:@"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
    };
    
    [self.controller playURN:URN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertNil([self.controller displayableSubdivisionAtTime:kCMTimeZero]);
}

@end
