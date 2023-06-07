//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

@import SRGLetterbox;

@interface PlaybackSettingsTestCase : LetterboxBaseTestCase

@end

@implementation PlaybackSettingsTestCase

#pragma mark Tests

- (void)testDefaultSettings
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    XCTAssertEqual(settings.streamType, SRGStreamTypeNone);
    XCTAssertEqual(settings.quality, SRGQualityNone);
    XCTAssertFalse(settings.standalone);
    XCTAssertNil(settings.sourceUid);
}

- (void)testCustomSettings
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.standalone = YES;
    settings.sourceUid = @"Source unique id";
    
    XCTAssertEqual(settings.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settings.quality, SRGQualityHD);
    XCTAssertTrue(settings.standalone);
    XCTAssertEqual(settings.sourceUid, @"Source unique id");
}

- (void)testCopy
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.standalone = YES;
    settings.sourceUid = @"Source unique id";
    
    // Make a copy
    SRGLetterboxPlaybackSettings *settingsCopy = settings.copy;
    
    // Modify the original
    settings.streamType = SRGStreamTypeNone;
    settings.quality = SRGQualityNone;
    settings.standalone = NO;
    settings.sourceUid = @"An other source unique id";
    
    // Check that the copy is identical to the original
    XCTAssertEqual(settingsCopy.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settingsCopy.quality, SRGQualityHD);
    XCTAssertTrue(settingsCopy.standalone);
    XCTAssertEqual(settingsCopy.sourceUid, @"Source unique id");
}

@end
