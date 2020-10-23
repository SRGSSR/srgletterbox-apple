//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGControlWrapperView.h"

@import libextobjc;
@import MAKVONotificationCenter;

@implementation SRGControlWrapperView

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    UIView *wrappedView = self.subviews.firstObject;
    
    if (newWindow) {
        @weakify(self)
        [wrappedView addObserver:self keyPath:@keypath(wrappedView.hidden) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateAppearance];
        }];
        [self updateAppearance];
    }
    else {
        [wrappedView removeObserver:self keyPath:@keypath(wrappedView.hidden)];
    }
}

#pragma mark Getters and setters

- (void)setMatchingFirstSubviewHidden:(BOOL)matchingFirstSubviewHidden
{
    _matchingFirstSubviewHidden = matchingFirstSubviewHidden;
    [self updateAppearance];
}

- (void)setAlwaysHidden:(BOOL)alwaysHidden
{
    _alwaysHidden = alwaysHidden;
    [self updateAppearance];
}

#pragma mark UI

- (void)updateAppearance
{
    if (self.alwaysHidden) {
        self.hidden = YES;
    }
    else if (self.matchingFirstSubviewHidden && self.subviews.firstObject) {
        self.hidden = self.subviews.firstObject.hidden;
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return self.subviews.firstObject ? @[self.subviews.firstObject] : nil;
}

@end

#endif
