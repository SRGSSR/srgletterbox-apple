//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"

NSString *SRGLetterboxMarketingVersion(void)
{
    return [NSBundle srg_letterboxBundle].infoDictionary[@"CFBundleShortVersionString"];
}
