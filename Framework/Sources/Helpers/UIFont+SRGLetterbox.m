//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIFont+SRGLetterbox.h"
#import "UIFontDescriptor+SRGLetterbox.h"
#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxLogger.h"

#import <CoreText/CoreText.h>

NSComparisonResult SRGCompareContentSizeCategories(NSString *contentSizeCategory1, NSString *contentSizeCategory2)
{
    if ([contentSizeCategory1 isEqualToString:contentSizeCategory2]) {
        return NSOrderedSame;
    }
    
    static NSArray *s_contentSizeCategories;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_contentSizeCategories = @[ UIContentSizeCategoryExtraSmall,
                                     UIContentSizeCategorySmall,
                                     UIContentSizeCategoryMedium,
                                     UIContentSizeCategoryLarge,
                                     UIContentSizeCategoryExtraLarge,
                                     UIContentSizeCategoryExtraExtraLarge,
                                     UIContentSizeCategoryExtraExtraExtraLarge,
                                     UIContentSizeCategoryAccessibilityMedium,
                                     UIContentSizeCategoryAccessibilityLarge,
                                     UIContentSizeCategoryAccessibilityExtraLarge,
                                     UIContentSizeCategoryAccessibilityExtraExtraLarge,
                                     UIContentSizeCategoryAccessibilityExtraExtraExtraLarge ];
    });
    
    NSUInteger index1 = [s_contentSizeCategories indexOfObject:contentSizeCategory1];
    NSCAssert(index1 != NSNotFound, @"Invalid content size");
    
    NSUInteger index2 = [s_contentSizeCategories indexOfObject:contentSizeCategory2];
    NSCAssert(index2 != NSNotFound, @"Invalid content size");
    
    if (index1 < index2) {
        return NSOrderedAscending;
    }
    else {
        return NSOrderedDescending;
    }
}

@implementation UIFont (SRGLetterbox)

__attribute__((constructor)) static void initializeRegisterSRGFonts(void)
{
    NSError *error = nil;
    NSArray<NSString *> *fontFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle srg_letterboxBundle] pathForResource:@"Fonts" ofType:nil]
                                                        error:&error];
    for (NSString *fontFileName in fontFileNames) {
        NSString *fontFilePath = [[[NSBundle srg_letterboxBundle] pathForResource:@"Fonts" ofType:nil] stringByAppendingPathComponent:fontFileName];
        NSData *inData = [NSData dataWithContentsOfFile:fontFilePath];
        if ([[fontFileName pathExtension] isEqualToString:@"ttf"] && inData) {
            CFErrorRef error;
            CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
            CGFontRef font = CGFontCreateWithDataProvider(provider);
            if (! CTFontManagerRegisterGraphicsFont(font, &error)) {
                CFStringRef errorDescription = CFErrorCopyDescription(error);
                SRGLetterboxLogError(@"RegisterFonts", @"Failed to load font %@: %@", fontFileName, errorDescription);
                CFRelease(errorDescription);
            }
            CFRelease(font);
            CFRelease(provider);
        }
    }
}

+ (UIFont *)srg_regularFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-Regular" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_boldFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-Bold" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_heavyFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-Heavy" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_lightFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-Light" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_mediumFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-Medium" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_italicFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-Italic" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_boldItalicFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRType-BoldItalic" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_regularSerifFontWithTextStyle:(NSString *)textStyle
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor srg_preferredFontDescriptorWithName:@"SRGSSRTypeSerif-Regular" textStyle:textStyle];
    return [UIFont fontWithDescriptor:fontDescriptor size:0.f];
}

+ (UIFont *)srg_regularFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-Regular" size:size];
}

+ (UIFont *)srg_boldFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-Bold" size:size];
}

+ (UIFont *)srg_heavyFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-Heavy" size:size];
}

+ (UIFont *)srg_lightFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-Light" size:size];
}

+ (UIFont *)srg_mediumFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-Medium" size:size];
}

+ (UIFont *)srg_italicFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-Italic" size:size];
}

+ (UIFont *)srg_boldItalicFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRType-BoldItalic" size:size];
}

+ (UIFont *)srg_regularSerifFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"SRGSSRTypeSerif-Regular" size:size];
}

@end
