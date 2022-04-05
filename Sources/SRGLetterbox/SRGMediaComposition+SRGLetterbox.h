//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalyticsDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaComposition (SRGLetterbox)

/**
 *  Returns the media object corresponding to the live (or scheduled live) media in the media composition.
 */
@property (nonatomic, readonly, nullable) SRGMedia *srgletterbox_liveMedia;

/**
 *  Return the chapter object which have the sprite sheet.
 *
 *  @discussion For chapter without a sprite sheet but the full length have one, full length chapter is returned if mark in and mark out exist.
 */
@property (nonatomic, readonly, nullable) SRGChapter *srgletterbox_spriteSheetChapter;

/**
 *  Consolidate segments and sibling chapters (segments from sibling chapters are omitted).
 */
- (NSArray<SRGSubdivision *> *)srgletterbox_subdivisionsForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController;

@end

NS_ASSUME_NONNULL_END
