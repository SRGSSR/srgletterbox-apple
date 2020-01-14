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
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGChapter * _Nullable chapter, NSDictionary<NSString *, id> * _Nullable bindings) {
                return chapter.contentType == SRGContentTypeLivestream || chapter.contentType == SRGContentTypeScheduledLivestream;
            }];
            SRGChapter *liveChapter = [self.chapters filteredArrayUsingPredicate:predicate].firstObject;
            return liveChapter ? [self mediaForSubdivision:liveChapter] : nil;
        }
    }
}

- (NSArray<SRGSubdivision *> *)srgletterbox_subdivisions
{
    // Show visible segments for the current chapter (if any), and display other chapters but not expanded. If
    // there is only a chapter, do not display it
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NO", @keypath(SRGSubdivision.new, hidden)];
    NSArray<SRGChapter *> *visibleChapters = [self.chapters filteredArrayUsingPredicate:predicate];
    
    NSMutableArray<SRGSubdivision *> *subdivisions = [NSMutableArray array];
    for (SRGChapter *chapter in visibleChapters) {
        if (chapter == self.mainChapter && chapter.segments.count != 0) {
            NSArray<SRGSegment *> *visibleSegments = [chapter.segments filteredArrayUsingPredicate:predicate];
            [subdivisions addObjectsFromArray:visibleSegments];
        }
        else if (visibleChapters.count > 1) {
            [subdivisions addObject:chapter];
        }
    }
    return subdivisions.copy;
}


@end
