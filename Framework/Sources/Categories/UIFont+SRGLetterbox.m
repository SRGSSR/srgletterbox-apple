//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIFont+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

__attribute__((constructor)) static void SRGLetterboxFontInit(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *fontFilePath = [NSBundle.srg_letterboxBundle pathForResource:@"FontAwesome" ofType:@"otf"];
        SRGAppearanceRegisterFont(fontFilePath);
    });
}

@implementation UIFont (SRGLetterbox)

+ (UIFont *)srg_awesomeFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"FontAwesome" size:size];
}

+ (UIFont *)srg_awesomeFontWithTextStyle:(NSString *)textStyle
{
    return [UIFont srg_fontWithName:@"FontAwesome" textStyle:textStyle];
}

@end
