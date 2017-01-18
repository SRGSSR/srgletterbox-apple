//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIFontDescriptor+SRGLetterbox.h"

@implementation UIFontDescriptor (SRGLetterbox)

+ (UIFontDescriptor *)srg_preferredFontDescriptorWithName:(NSString *)name textStyle:(NSString *)style
{
    // Currently use the sizes specified for the system font, for which we cache values in a table for faster queries. We
    // can create a custom table (even with custom categories) later if needed, see http://stackoverflow.com/a/20510095/760435
    
    static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, UIFontDescriptor *> *> *s_fontDescriptorMap;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_fontDescriptorMap = [NSMutableDictionary dictionary];
    });
    
    NSMutableDictionary<NSString *, UIFontDescriptor *> *fontDescriptorForCategoryMap = s_fontDescriptorMap[style];
    if (!fontDescriptorForCategoryMap) {
        fontDescriptorForCategoryMap = [NSMutableDictionary dictionary];
        s_fontDescriptorMap[style] = fontDescriptorForCategoryMap;
    }
    
    NSString *contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    UIFontDescriptor *fontDescriptor = fontDescriptorForCategoryMap[contentSizeCategory];
    if (!fontDescriptor) {
        UIFontDescriptor *systemFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
        CGFloat size = [systemFontDescriptor.fontAttributes[UIFontDescriptorSizeAttribute] floatValue];
        fontDescriptor = [UIFontDescriptor fontDescriptorWithName:name size:size];
        fontDescriptorForCategoryMap[contentSizeCategory] = fontDescriptor;
    }
    
    return fontDescriptor;
}

@end
