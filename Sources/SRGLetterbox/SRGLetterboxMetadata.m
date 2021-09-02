//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxMetadata.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateFormatter+SRGLetterbox.h"

static BOOL SRGLetterboxMetadataAreRedundant(SRGMedia *media, SRGShow *show)
{
    return [media.show.title.lowercaseString isEqualToString:media.title.lowercaseString];
}

NSString *SRGLetterboxMetadataTitle(SRGMedia *media)
{
    if (SRGLetterboxMetadataAreRedundant(media, media.show)) {
        return [NSDateFormatter.srgletterbox_relativeDateAndTimeFormatter stringFromDate:media.date];
    }
    else {
        return media.title;
    }
}

NSString *SRGLetterboxMetadataSubtitle(SRGMedia *media)
{
    return media.show.title;
}

NSString *SRGLetterboxMetadataDescription(SRGMedia *media)
{
    if (media.summary && media.imageCopyright) {
        NSString *imageCopyright = [NSString stringWithFormat:SRGLetterboxLocalizedString(@"Image credit: %@", @"Image copyright introductory label"), media.imageCopyright];
        return [NSString stringWithFormat:@"%@\n\n%@", media.summary, imageCopyright];
    }
    else if (media.imageCopyright) {
        return [NSString stringWithFormat:SRGLetterboxLocalizedString(@"Image credit: %@", @"Image copyright introductory label"), media.imageCopyright];
    }
    else {
        return media.summary;
    }
}
