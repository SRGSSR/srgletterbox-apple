//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxBaseView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxView+Private.h"

#import <Masonry/Masonry.h>

static void commonInit(SRGLetterboxBaseView *self);

@interface SRGLetterboxBaseView ()

@property (nonatomic) UIView *nibView;         // Strong

@end

@implementation SRGLetterboxBaseView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
        
        // The top-level view loaded from the xib file and initialized in `commonInit` is NOT a instance of the class.
        // Manually calling `-awakeFromNib` forces the final view initialization (also see comments in `commonInit`).
        [self awakeFromNib];
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
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(accessibilityVoiceOverStatusChanged:)
                                                   name:UIAccessibilityVoiceOverStatusChanged
                                                 object:nil];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIContentSizeCategoryDidChangeNotification
                                                    object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIAccessibilityVoiceOverStatusChanged
                                                    object:nil];
    }
}

#pragma mark Subclassing hooks

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

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self voiceOverStatusDidChange];
}

#pragma mark Layout

- (void)setNeedsLayoutAnimated:(BOOL)animated
{
    [self.parentLetterboxView setNeedsLayoutAnimated:animated];
}

@end

static void commonInit(SRGLetterboxBaseView *self)
{
    NSString *nibName = NSStringFromClass(self.class);
    if ([NSBundle.srg_letterboxBundle pathForResource:nibName ofType:@"nib"]) {
        // This makes design in a xib and Interface Builder preview (IB_DESIGNABLE) work. The top-level view must NOT be
        // an instance of the class itself to avoid infinite recursion.
        self.nibView = [[NSBundle.srg_letterboxBundle loadNibNamed:nibName owner:self options:nil] firstObject];
        self.nibView.backgroundColor = UIColor.clearColor;
        [self addSubview:self.nibView];
        [self.nibView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
}
