//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGMediaComposition.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaComposition (SRGLetterbox)

/**
 *  Return the media object corresponding to the live (or scheduled live) media in the media composition.
 *
 *  @param Media from the mainChapter, the full-length chapter or the first live (or scheduled live) stream chapter found.
 */
@property (nonatomic, readonly, nullable) SRGMedia *liveMedia;

@end

NS_ASSUME_NONNULL_END
