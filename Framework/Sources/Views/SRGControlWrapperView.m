//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlWrapperView.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@implementation SRGControlWrapperView

#pragma mark Getters and setters

- (void)setWrappedView:(UIView *)wrappedView
{
    if (_wrappedView) {
        [_wrappedView removeObserver:self keyPath:@keypath(_wrappedView.hidden)];
    }
    
    _wrappedView = wrappedView;
    
    if (wrappedView) {
        @weakify(self)
        [wrappedView addObserver:self keyPath:@keypath(wrappedView.hidden) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            [self updateHidden];
        }];
    }
    
    [self updateHidden];
}

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
    else if (self.observingWrappedViewHidden && self.wrappedView) {
        self.hidden = self.wrappedView.hidden;
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
    return (self.wrappedView) ? @[self.wrappedView] : nil;
}

@end
