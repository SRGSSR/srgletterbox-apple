//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaComposition (SRGLetterbox)

/**
 *  Returns the media object corresponding to the live (or scheduled live) media in the media composition.
 */
@property (nonatomic, readonly, nullable) SRGMedia *srgletterbox_liveMedia;

/**
 *  Consolidate segments and sibling chapters (segments from sibling chapters are omitted).
 */
- (NSArray<SRGSubdivision *> *)srgletterbox_subdivisionsForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController;

@end

NS_ASSUME_NONNULL_END
