//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"
#import "Playlist.h"

#import <SRGLetterbox/SRGLetterbox.h>

static SRGMediaURN *MediaURN1(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:9309820"];
}

static SRGMediaURN *MediaURN2(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:9314051"];
}

static SRGMediaURN *MediaSegmentURN1(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:9314065"];
}

static SRGMediaURN *MediaSegmentURN2(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:9314069"];
}

static SRGMediaURN *InvalidURN(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:123456"];
}

@interface PlaylistsTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic) SRGLetterboxController *controller;
@property (nonatomic) Playlist *playlist;

@end

@implementation PlaylistsTestCase

#pragma mark Setup and tear down

- (void)setUp
{
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRTS];
    self.controller = [[SRGLetterboxController alloc] init];
}

- (void)tearDown
{
    // Always ensure the player gets deallocated between tests
    [self.controller reset];
    self.controller = nil;
}

#pragma mark Tests

- (void)testPlaylistPlaythrough
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertNil(self.controller.URN);
    XCTAssertEqualObjects(self.controller.nextMedia, self.playlist.medias.firstObject);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL success1 = [self.controller playNextMedia];
    XCTAssertTrue(success1);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.nextMedia, self.playlist.medias.lastObject);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL success2 = [self.controller playNextMedia];
    XCTAssertTrue(success2);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.previousMedia, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.lastObject);
    XCTAssertNil(self.controller.nextMedia);
    
    BOOL success3 = [self.controller playNextMedia];
    XCTAssertFalse(success3);
}

- (void)testReversePlaylistPlaythrough
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertNil(self.controller.URN);
    XCTAssertEqualObjects(self.controller.nextMedia, self.playlist.medias.firstObject);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playMedia:self.playlist.medias.lastObject withChaptersOnly:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.previousMedia, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.lastObject);
    XCTAssertNil(self.controller.nextMedia);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL success1 = [self.controller playPreviousMedia];
    XCTAssertTrue(success1);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.nextMedia, self.playlist.medias.lastObject);
    
    BOOL success3 = [self.controller playPreviousMedia];
    XCTAssertFalse(success3);
}

- (void)testNoPlaylist
{
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURN:MediaURN1() withChaptersOnly:NO];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertNil(self.controller.nextMedia);
}

- (void)testPlaylistFromSegments
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaSegmentURN1(), MediaSegmentURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    BOOL success1 = [self.controller playNextMedia];
    XCTAssertTrue(success1);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, MediaSegmentURN1());
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateSeeking;
    }];
    
    BOOL success2 = [self.controller playNextMedia];
    XCTAssertTrue(success2);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, MediaSegmentURN2());
}

- (void)testPlaylistsFromChapters
{
    
}

- (void)testDefaultContinuousPlayback
{
    
}

- (void)testDisabledContinuousPlayback
{
    
}

- (void)testImmediateContinuousPlayback
{
    
}

- (void)testContinuousPlaybackWithInvalidMedia
{
    
}

- (void)testContinuousPlaybackWithScheduledLivestream
{
    
}

- (void)testPlaybackSettingsReuse
{
    
}

@end
