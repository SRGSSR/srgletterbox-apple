//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"

#import "SRGLetterboxView+Private.h"

static void commonInit(SRGLetterboxBaseView *self);

@interface SRGLetterboxBaseView ()

// Instantiated at initialization time (so that outlets are readily defined), but only installed when displayed
// to improve performance.
@property (nonatomic) UIView *contentView;

@end

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
        [self addSubview:self.contentView];
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
            [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor]
        ]];
        
        [self contentSizeCategoryDidChange];
        [self voiceOverStatusDidChange];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(contentSizeCategoryDidChange:)
                                                   name:UIContentSizeCategoryDidChangeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(accessibilityVoiceOverStatusDidChange:)
                                                   name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                                 object:nil];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIContentSizeCategoryDidChangeNotification
                                                    object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                                    object:nil];
    }
}

#pragma mark Subclassing hooks

- (void)layoutContentView
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

static void commonInit(SRGLetterboxBaseView *self)
{
    self.contentView = [[UIView alloc] init];
    [self layoutContentView];
}
