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
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.controller handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    [self.controller playURL:OnDemandTestURL() atTime:kCMTimeZero withSegments:nil userInfo:nil];
    [self waitForExpectationsWithTimeout:30. handler:nil];
}

- (void)testLiveStreamSeeks
{

}

- (void)testDVRStreamSeeks
{

}

@end
