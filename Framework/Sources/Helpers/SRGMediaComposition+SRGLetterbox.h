//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGMediaComposition.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaComposition (SRGLetterbox)

/**
 *  Returns the media object corresponding to the live (or scheduled live) media in the media composition.
 */
@property (nonatomic, readonly, nullable) SRGMedia *srgletterbox_liveMedia;

@property (nonatomic, readonly, nullable) NSArray<SRGSubdivision *> *srgletterbox_subdivisions;

@end

NS_ASSUME_NONNULL_END
