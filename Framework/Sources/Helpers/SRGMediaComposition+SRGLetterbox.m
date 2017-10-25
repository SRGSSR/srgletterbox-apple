//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaComposition+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>

@implementation SRGMediaComposition (SRGLetterbox)

- (SRGMedia *)srgletterbox_liveMedia
{
    if (self.mainChapter.contentType == SRGContentTypeLivestream || self.mainChapter.contentType == SRGContentTypeScheduledLivestream) {
        return [self mediaForSubdivision:self.mainChapter];
    }
    else {
        SRGMedia *fullLengthMedia = self.fullLengthMedia;
        if (fullLengthMedia.contentType == SRGContentTypeLivestream || fullLengthMedia.contentType == SRGContentTypeScheduledLivestream) {
            return fullLengthMedia;
        }
        else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ || %K == %@", @keypath(SRGChapter.new, contentType), @(SRGContentTypeLivestream), @keypath(SRGChapter.new, contentType), @(SRGContentTypeScheduledLivestream)];
            SRGChapter *liveChapter = [self.chapters filteredArrayUsingPredicate:predicate].firstObject;
            return liveChapter ? [self mediaForSubdivision:liveChapter] : nil;
        }
    }
}

@end
