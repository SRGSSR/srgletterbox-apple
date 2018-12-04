//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxPlaybackSettings.h"

@implementation SRGLetterboxPlaybackSettings

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.streamType = SRGStreamTypeNone;
        self.quality = SRGQualityNone;
        self.startBitRate = SRGDefaultStartBitRate;
        self.standalone = NO;
    }
    return self;
}

#pragma mark NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
    SRGLetterboxPlaybackSettings *settings = [self.class allocWithZone:zone];
    settings.streamType = self.streamType;
    settings.quality = self.quality;
    settings.startBitRate = self.startBitRate;
    settings.standalone = self.standalone;
    return settings;
}

@end
