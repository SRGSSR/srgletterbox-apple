//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlWrapperView.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@implementation SRGControlWrapperView

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        UIView *wrappedView = self.subviews.firstObject;
        if (wrappedView) {
            @weakify(self)
            [wrappedView addObserver:self keyPath:@keypath(wrappedView.hidden) options:0 block:^(MAKVONotification *notification) {
                @strongify(self)
                [self updateHidden];
            }];
        }
        [self updateHidden];
    }
    else {
        UIView *wrappedView = self.subviews.firstObject;
        if (wrappedView) {
            [wrappedView removeObserver:self keyPath:@keypath(wrappedView.hidden)];
        }
    }
}

#pragma mark Getters and setters

- (void)setAlwaysHidden:(BOOL)alwaysHidden
{
    _alwaysHidden = alwaysHidden;
    [self updateHidden];
}

#pragma mark UI

- (void)updateHidden
{
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (self.observingFirstSubviewHidden && self.subviews.firstObject) {
        self.hidden = self.subviews.firstObject.hidden;
    }
    else {
        // By default, don't hide the view.
        self.hidden = NO;
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return (self.subviews.firstObject) ? @[self.subviews.firstObject] : nil;
}

@end
