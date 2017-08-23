//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+SRGLetterbox.h"

@implementation NSString (SRGLetterbox)

- (NSString *)srg_localizedUppercaseFirstLetterString
{
    NSString *firstUppercaseCharacter = [self substringToIndex:1].localizedUppercaseString;
    return [firstUppercaseCharacter stringByAppendingString:[self substringFromIndex:1]];
}

@end
