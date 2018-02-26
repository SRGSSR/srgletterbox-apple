//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"
#import "Playlist.h"

#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>

static SRGMediaURN *MediaURN1(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:9309820"];
}

static SRGMediaURN *MediaURN2(void)
{
    return [SRGMediaURN mediaURNWithString:@"urn:rts:video:9314051"];
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
    
    XCTAssertTrue([self.controller canPlayNextMedia]);
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.nextMedia, self.playlist.medias.lastObject);
    
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller canPlayNextMedia]);
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.previousMedia, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.lastObject);
    XCTAssertNil(self.controller.nextMedia);
    
    XCTAssertFalse([self.controller canPlayNextMedia]);
    XCTAssertFalse([self.controller playNextMedia]);
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
    
    XCTAssertTrue([self.controller canPlayPreviousMedia]);
    XCTAssertTrue([self.controller playPreviousMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.previousMedia);
    XCTAssertEqualObjects(self.controller.media, self.playlist.medias.firstObject);
    XCTAssertEqualObjects(self.controller.nextMedia, self.playlist.medias.lastObject);
    
    XCTAssertFalse([self.controller canPlayPreviousMedia]);
    XCTAssertFalse([self.controller playPreviousMedia]);
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
    
    XCTAssertFalse([self.controller canPlayNextMedia]);
    XCTAssertFalse([self.controller playNextMedia]);
    
    XCTAssertFalse([self.controller canPlayPreviousMedia]);
    XCTAssertFalse([self.controller playPreviousMedia]);
    
    XCTAssertFalse([self.controller prepareToPlayNextMediaWithCompletionHandler:^{
        XCTFail(@"Must not be called");
    }]);
    XCTAssertFalse([self.controller prepareToPlayPreviousMediaWithCompletionHandler:^{
        XCTFail(@"Must not be called");
    }]);
}

- (void)testDefaultContinuousPlayback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start with the first item in the playlist
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Seek near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    NSDate *playbackEndDate1 = NSDate.date;
    
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertEqualObjects(self.controller.continuousPlaybackUpcomingMedia.URN, MediaURN2());
    
    // Wait until the next media is played automatically
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackDidContinueAutomaticallyNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
        return [media.URN isEqual:MediaURN2()];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, MediaURN2());
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    XCTAssertTrue([NSDate.date timeIntervalSinceDate:playbackEndDate1] - SRGLetterboxContinuousPlaybackTransitionDurationDefault < 1);
}

- (void)testDisabledContinuousPlayback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    self.controller.continuousPlaybackTransitionDuration = SRGLetterboxContinuousPlaybackTransitionDurationDisabled;
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start with the first item in the playlist
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Seek near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Wait some time. We don't expect playback to automatically continue with the next item
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must remain in the current state");
    }];
    
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackDidContinueAutomaticallyNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not continue automatically");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, MediaURN1());
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
}

- (void)testImmediateContinuousPlayback
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    self.controller.continuousPlaybackTransitionDuration = SRGLetterboxContinuousPlaybackTransitionDurationImmediate;
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start with the first item in the playlist
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Seek near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackDidContinueAutomaticallyNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
        return [media.URN isEqual:MediaURN2()];
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    NSDate *playbackEndDate1 = NSDate.date;
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Wait until the next media is played automatically
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, MediaURN2());
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    XCTAssertTrue([NSDate.date timeIntervalSinceDate:playbackEndDate1] < 1);
}

- (void)testContinuousPlaybackCancellation
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // No effect, no pending continuation
    [self.controller cancelContinuousPlayback];
    
    // Start with the first item in the playlist
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // No effect, no pending continuation
    [self.controller cancelContinuousPlayback];
    
    // Seek near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Cancel pending continuation. The second media will not be played automatically
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertEqualObjects(self.controller.continuousPlaybackUpcomingMedia.URN, MediaURN2());
    
    [self.controller cancelContinuousPlayback];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Wait some time. We don't expect playback to automatically continue with the next item
    id eventObserver1 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must remain in the current state");
    }];
    
    id eventObserver2 = [[NSNotificationCenter defaultCenter] addObserverForName:SRGLetterboxPlaybackDidContinueAutomaticallyNotification object:self.controller queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"The player must not continue automatically");
    }];
    
    [self expectationForElapsedTimeInterval:10. withHandler:nil];
    
    [self waitForExpectationsWithTimeout:20. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver1];
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver2];
    }];
    
    XCTAssertEqualObjects(self.controller.URN, MediaURN1());
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
}

- (void)testPlaylistChangesDuringContinuousPlaybackTransition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start with the first item in the playlist
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    // Seek near the end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    NSDate *playbackEndDate1 = NSDate.date;
    
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertEqualObjects(self.controller.continuousPlaybackUpcomingMedia.URN, MediaURN2());
    
    // Change the playlist (e.g. clear it)
    self.playlist = nil;
    
    // The media to be played next is not affected by the playlist update
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNotNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertEqualObjects(self.controller.continuousPlaybackUpcomingMedia.URN, MediaURN2());
    
    // The next media which was previously found will still be played
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    
    [self expectationForNotification:SRGLetterboxPlaybackDidContinueAutomaticallyNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
        return [media.URN isEqual:MediaURN2()];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    XCTAssertEqualObjects(self.controller.URN, MediaURN2());
    XCTAssertNil(self.controller.continuousPlaybackTransitionStartDate);
    XCTAssertNil(self.controller.continuousPlaybackTransitionEndDate);
    XCTAssertNil(self.controller.continuousPlaybackUpcomingMedia);
    
    XCTAssertTrue([NSDate.date timeIntervalSinceDate:playbackEndDate1] - SRGLetterboxContinuousPlaybackTransitionDurationDefault < 1);
}

- (void)testContinuousPlaybackTransitionKeyValueObserving
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Media request"];
    
    [[self.dataProvider mediasWithURNs:@[MediaURN1(), MediaURN2()] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        self.playlist = [[Playlist alloc] initWithMedias:medias];
        self.controller.playlistDataSource = self.playlist;
        [expectation fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Start with the first item in the playlist
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    XCTAssertTrue([self.controller playNextMedia]);
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Seek near the end end wait for the transition to start
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStateEnded;
    }];
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, continuousPlaybackTransitionStartDate) handler:^BOOL(SRGLetterboxController * _Nonnull controller, NSDictionary * _Nonnull change) {
        return controller.continuousPlaybackTransitionStartDate != nil;
    }];
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, continuousPlaybackTransitionEndDate) handler:^BOOL(SRGLetterboxController * _Nonnull controller, NSDictionary * _Nonnull change) {
        return controller.continuousPlaybackTransitionEndDate != nil;
    }];
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, continuousPlaybackUpcomingMedia) handler:^BOOL(SRGLetterboxController * _Nonnull controller, NSDictionary * _Nonnull change) {
        return [controller.continuousPlaybackUpcomingMedia.URN isEqual:MediaURN2()];
    }];
    
    [self.controller seekPreciselyToTime:CMTimeSubtract(CMTimeRangeGetEnd(self.controller.timeRange), CMTimeMakeWithSeconds(5., NSEC_PER_SEC)) withCompletionHandler:nil];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
    
    // Wait for the transition to end
    [self expectationForNotification:SRGLetterboxPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePreparing;
    }];
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, continuousPlaybackTransitionStartDate) handler:^BOOL(SRGLetterboxController * _Nonnull controller, NSDictionary * _Nonnull change) {
        return controller.continuousPlaybackTransitionStartDate == nil;
    }];
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, continuousPlaybackTransitionEndDate) handler:^BOOL(SRGLetterboxController * _Nonnull controller, NSDictionary * _Nonnull change) {
        return controller.continuousPlaybackTransitionEndDate == nil;
    }];
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, continuousPlaybackUpcomingMedia) handler:^BOOL(SRGLetterboxController * _Nonnull controller, NSDictionary * _Nonnull change) {
        return controller.continuousPlaybackUpcomingMedia.URN == nil;
    }];
    [self expectationForNotification:SRGLetterboxPlaybackDidContinueAutomaticallyNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
        return [media.URN isEqual:MediaURN2()];
    }];
    
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

@end
