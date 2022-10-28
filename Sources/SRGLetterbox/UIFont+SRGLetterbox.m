//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIFont+SRGLetterbox.h"

@import CoreText;
@import SRGAppearance;

__attribute__((constructor)) static void SRGLetterboxFontInit(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *fontFileURL = [SWIFTPM_MODULE_BUNDLE URLForResource:@"FontAwesome" withExtension:@"otf"];
        BOOL success = CTFontManagerRegisterFontsForURL((CFURLRef)fontFileURL, kCTFontManagerScopeProcess, NULL);
        if (! success) {
            NSLog(@"The FontAwesome font could not be registered. Please ensure only SRG Letterbox registers "
                  "this font (check font declarations in your application Info.plist). Please ignore this "
                  "issue in unit tests.");
        }
    });
}

@implementation UIFont (SRGLetterbox)

+ (UIFont *)srg_awesomeFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"FontAwesome" size:size];
}

+ (UIFont *)srg_awesomeFontWithStyle:(SRGFontStyle)style
{
    CGFloat size = [SRGFont sizeForFontStyle:style];
    UIFont *font = [UIFont fontWithName:@"FontAwesome" size:size];
    
    UIFontTextStyle textStyle = [SRGFont textStyleForFontStyle:style];
    UIFontMetrics *metrics = [UIFontMetrics metricsForTextStyle:textStyle];
    return [metrics scaledFontForFont:font];
}

@end
