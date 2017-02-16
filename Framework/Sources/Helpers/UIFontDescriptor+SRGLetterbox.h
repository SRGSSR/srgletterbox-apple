//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

// TODO: Create an SRGFonts framework

NS_ASSUME_NONNULL_BEGIN

/**
 *  Font descriptor extensions
 */
@interface UIFontDescriptor (SRGLetterbox)

+ (UIFontDescriptor *)srg_preferredFontDescriptorWithName:(NSString *)name textStyle:(NSString *)style;

@end

NS_ASSUME_NONNULL_END
