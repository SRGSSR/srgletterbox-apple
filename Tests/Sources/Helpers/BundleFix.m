//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Fix so that unit tests use the test bundle, not the host bundle, as main bundle. This is required since comScore
// internally uses the main bundle info plist to fill some labels. Since the host bundle info plist misses some
// pieces of information comScore uses and does not perform safety checks, using the host bundle would crash

@interface DummyClass : NSObject
@end

@implementation DummyClass
@end

@interface NSBundle (TestFix)
@end

@implementation NSBundle (TestFix)

+ (void)load
{
    method_exchangeImplementations(class_getClassMethod(self, @selector(mainBundle)),
                                   class_getClassMethod(self, @selector(swizzled_mainBundle)));
}

+ (NSBundle *)swizzled_mainBundle
{
    return [NSBundle bundleForClass:[DummyClass class]];
}

@end
