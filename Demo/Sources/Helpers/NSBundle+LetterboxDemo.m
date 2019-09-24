//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+LetterboxDemo.h"

NSString *LetterboxDemoNonLocalizedString(NSString *string)
{
    return string;
}

NSString *LetterboxDemoResourceNameForUIClass(Class cls)
{
    NSString *name = NSStringFromClass(cls);
#if TARGET_OS_TV
    return [name stringByAppendingString:@"~tvos"];
#else
    return [name stringByAppendingString:@"~ios"];
#endif
}
