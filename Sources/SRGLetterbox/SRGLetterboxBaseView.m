//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"

#import "SRGLetterboxView+Private.h"

static void commonInit(SRGLetterboxBaseView *self);

@implementation SRGLetterboxBaseView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

#if TARGET_OS_IOS

- (SRGLetterboxView *)parentLetterboxView
{
    // Start with self. The context can namely be the receiver itself
    UIView *parentLetterboxView = self;
    while (parentLetterboxView) {
        if ([parentLetterboxView isKindOfClass:SRGLetterboxView.class]) {
            return (SRGLetterboxView *)parentLetterboxView;
        }
        parentLetterboxView = parentLetterboxView.superview;
    }
    return nil;
}

#endif

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self contentSizeCategoryDidChange];
        [self voiceOverStatusDidChange];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(contentSizeCategoryDidChange:)
                                                   name:UIContentSizeCategoryDidChangeNotification
                                                 object:nil];
        
#if TARGET_OS_IOS
        if (@available(iOS 11, *)) {
#endif
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(accessibilityVoiceOverStatusDidChange:)
                                                       name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                                     object:nil];
#if TARGET_OS_IOS
        }
        else {
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(accessibilityVoiceOverStatusDidChange:)
                                                       name:UIAccessibilityVoiceOverStatusChanged
                                                     object:nil];
        }
#endif
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIContentSizeCategoryDidChangeNotification
                                                    object:nil];
        
#if TARGET_OS_IOS
        if (@available(iOS 11, *)) {
#endif
            [NSNotificationCenter.defaultCenter removeObserver:self
                                                          name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                                        object:nil];
#if TARGET_OS_IOS
        }
        else {
            [NSNotificationCenter.defaultCenter removeObserver:self
                                                          name:UIAccessibilityVoiceOverStatusChanged
                                                        object:nil];
        }
#endif
    }
}

#pragma mark Subclassing hooks

- (void)createView
{}

- (void)contentSizeCategoryDidChange
{}

- (void)voiceOverStatusDidChange
{}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{}

#pragma mark Notifications

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self contentSizeCategoryDidChange];
}

- (void)accessibilityVoiceOverStatusDidChange:(NSNotification *)notification
{
    [self voiceOverStatusDidChange];
}

#pragma mark Layout

#if TARGET_OS_IOS

- (void)setNeedsLayoutAnimated:(BOOL)animated
{
    [self.parentLetterboxView setNeedsLayoutAnimated:animated];
}

#endif

@end

static void commonInit(SRGLetterboxView *self)
{
    [self createView];
}
