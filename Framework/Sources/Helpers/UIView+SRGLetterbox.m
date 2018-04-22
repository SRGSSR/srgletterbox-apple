//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIView+SRGLetterbox.h"

#import <objc/runtime.h>

static void *s_alwaysHiddenKey = &s_alwaysHiddenKey;

@implementation UIView (SRGLetterbox)

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(isHidden)),
                                   class_getInstanceMethod(self, @selector(swizzled_isHidden)));
}

- (BOOL)swizzled_isHidden
{
    if (self.srg_alwaysHidden) {
        return YES;
    }
    else {
        return [self swizzled_isHidden];
    }
}

- (BOOL)srg_alwaysHidden
{
    return [objc_getAssociatedObject(self, s_alwaysHiddenKey) boolValue];
}

- (void)setSrg_alwaysHidden:(BOOL)alwaysHidden
{
    objc_setAssociatedObject(self, s_alwaysHiddenKey, @(alwaysHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
