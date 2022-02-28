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

NSString *LetterboxDemoAccessibilityLocalizedString(NSString *key, __unused NSString *comment)
{
    return [NSBundle.mainBundle localizedStringForKey:key value:@"" table:@"Accessibility"];
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

@implementation NSBundle (SRGLetterbox)

- (NSString *)letterbox_demo_friendlyVersionNumber
{
    NSString *shortVersionString = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *marketingVersion = [shortVersionString componentsSeparatedByString:@"-"].firstObject ?: shortVersionString;
    
    NSString *bundleVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"];
    
    NSString *bundleDisplayNameSuffix = [NSBundle.mainBundle.infoDictionary objectForKey:@"BundleDisplayNameSuffix"];
    NSString *buildName = [NSBundle.mainBundle.infoDictionary objectForKey:@"BuildName"];
    NSString *friendlyBuildName = [NSString stringWithFormat:@"%@%@",
                                   bundleDisplayNameSuffix.length > 0 ? bundleDisplayNameSuffix : @"",
                                   buildName.length > 0 ? [@" " stringByAppendingString:buildName] : @""];
    
    NSString *version = [NSString stringWithFormat:@"%@ (%@)%@", marketingVersion, bundleVersion, friendlyBuildName];
    if ([self letterbox_demo_isTestFlightDistribution]) {
        // Unbreakable spaces before / after the separator
        version = [version stringByAppendingString:@" - TF"];
    }
    return version;
}

- (BOOL)letterbox_demo_isTestFlightDistribution
{
#if !defined(DEBUG) && !defined(APPCENTER)
    return (self.appStoreReceiptURL.path && [self.appStoreReceiptURL.path rangeOfString:@"sandboxReceipt"].location != NSNotFound);
#else
    return NO;
#endif
}

@end
