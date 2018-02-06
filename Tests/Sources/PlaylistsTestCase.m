//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface PlaylistsTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation PlaylistsTestCase

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

- (void)testSimplePlaylist
{
    
}

- (void)testPlaylistWithoutNextMedia
{
    
}

- (void)testPlaylistWithoutPreviousMedia
{
    
}

- (void)testEmptyPlaylist
{
    
}

- (void)testNoPlaylist
{
    
}

- (void)testPlaylistWithRepeatedMedia
{
    
}

- (void)testPlaylistWithInvalidMedia
{
    
}

- (void)testPlaylistFromSegments
{
    
}

- (void)testPlaylistsFromChapters
{
    
}

- (void)testPlaylistWithScheduledLivestream
{
    
}

- (void)testContinuousPlayback
{
    
}

- (void)testDisabledContinuousPlayback
{
    
}

- (void)testImmediateContinuousPlayback
{
    
}

@end
