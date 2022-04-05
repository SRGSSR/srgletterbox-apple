//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaComposition+SRGLetterbox.h"

@import libextobjc;

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

- (SRGChapter *)srgletterbox_spriteSheetChapter
{
    SRGChapter *mainChapter = self.mainChapter;
    if (mainChapter.spriteSheet) {
        return mainChapter;
    }
    else if (mainChapter.fullLengthURN && mainChapter.fullLengthMarkIn != 0 && mainChapter.fullLengthMarkOut != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGChapter.new, URN), mainChapter.fullLengthURN];
        SRGChapter *fullLengthChapter = [self.chapters filteredArrayUsingPredicate:predicate].firstObject;
        return fullLengthChapter.spriteSheet != nil ? fullLengthChapter : nil;
    }
    else {
        return nil;
    }
}

- (NSArray<SRGSubdivision *> *)srgletterbox_subdivisionsForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    // Show visible segments for the current chapter (if any), and display other chapters but not expanded. If
    // there is only a chapter, do not display it
    NSPredicate *chaptersPredicate = [NSPredicate predicateWithFormat:@"%K == NO", @keypath(SRGSubdivision.new, hidden)];
    NSArray<SRGChapter *> *visibleChapters = [self.chapters filteredArrayUsingPredicate:chaptersPredicate];
    
    NSMutableArray<SRGSubdivision *> *subdivisions = [NSMutableArray array];
    for (SRGChapter *chapter in visibleChapters) {
        if (chapter == self.mainChapter && chapter.segments.count != 0) {
            NSPredicate *segmentsPredicate = [NSPredicate predicateWithBlock:^BOOL(SRGSegment * _Nullable segment, NSDictionary<NSString *, id> * _Nullable bindings) {
                if (segment.hidden || ! mediaPlayerController) {
                    return NO;
                }
                
                CMTimeRange segmentTimeRange = [segment.srg_markRange timeRangeForMediaPlayerController:mediaPlayerController];
                return CMTimeRangeContainsTime(mediaPlayerController.timeRange, segmentTimeRange.start);
            }];
            NSArray<SRGSegment *> *visibleSegments = [chapter.segments filteredArrayUsingPredicate:segmentsPredicate];
            [subdivisions addObjectsFromArray:visibleSegments];
        }
        else if (visibleChapters.count > 1) {
            [subdivisions addObject:chapter];
        }
    }
    return subdivisions.copy;
}

@end
