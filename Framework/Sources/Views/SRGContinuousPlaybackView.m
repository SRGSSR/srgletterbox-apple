//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuousPlaybackView.h"

#import "NSBundle+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

static void commonInit(SRGContinuousPlaybackView *self);

@interface SRGContinuousPlaybackView ()

@property (weak) id periodicTimeObserver;

@end

@implementation SRGContinuousPlaybackView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
        
        // The top-level view loaded from the xib file and initialized in `commonInit` is NOT an SRGContinuousPlaybackView. Manually
        // calling `-awakeFromNib` forces the final view initialization (also see comments in `commonInit`).
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

- (void)setController:(SRGLetterboxController *)controller
{
    if (_controller) {
        [_controller removePeriodicTimeObserver:self.periodicTimeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SRGLetterboxPlaybackStateDidChangeNotification
                                                      object:_controller];
    }
    
    _controller = controller;
    [self refreshView];
    
    if (controller) {
        @weakify(self)
        self.periodicTimeObserver = [controller addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
            @strongify(self)
            
            [self refreshView];
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateDidChange:)
                                                     name:SRGLetterboxPlaybackStateDidChangeNotification
                                                   object:controller];
    }
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // TODO:
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self refreshView];
    }
}

#pragma mark UI

- (void)refreshView
{
    if (self.controller.playbackState == SRGMediaPlayerPlaybackStateEnded) {
        self.hidden = NO;
    }
    else {
        self.hidden = YES;
    }
}

#pragma mark Notifications

- (void)playbackStateDidChange:(NSNotification *)notification
{
    [self refreshView];
}

@end

static void commonInit(SRGContinuousPlaybackView *self)
{
    // This makes design in a xib and Interface Builder preview (IB_DESIGNABLE) work. The top-level view must NOT be
    // an SRGCountdownView to avoid infinite recursion
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    view.backgroundColor = [UIColor clearColor];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.hidden = YES;
}
