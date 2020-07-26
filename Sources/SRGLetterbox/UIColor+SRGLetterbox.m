//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIColor+SRGLetterbox.h"

@import SRGAppearance;

@implementation UIColor (SRGLetterbox)

+ (UIColor *)srg_liveRedColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#d50000"];
}

+ (UIColor *)srg_progressRedColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#d50000"];
}

+ (UIColor *)srg_placeholderBackgroundGrayColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#202020"];
}

@end
