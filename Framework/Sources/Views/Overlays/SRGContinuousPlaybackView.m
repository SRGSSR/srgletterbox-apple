//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGContinuousPlaybackView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxController+Private.h"
#import "SRGLetterboxControllerView+Subclassing.h"
#import "SRGLetterboxView+Private.h"
#import "SRGRemainingTimeButton.h"
#import "SRGStackView.h"
#import "UIImage+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SRGContinuousPlaybackView ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet SRGStackView *stackView;

@property (nonatomic, weak) UILabel *introLabel;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *subtitleLabel;
@property (nonatomic, weak) SRGRemainingTimeButton *remainingTimeButton;
@property (nonatomic, weak) UIButton *cancelButton;

@end

@implementation SRGContinuousPlaybackView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.stackView.spacing = 2.f;
    
    UIView *spacerView1 = [[UIView alloc] init];
    [self.stackView addSubview:spacerView1];
    
    UILabel *introLabel = [[UILabel alloc] init];
    introLabel.text = SRGLetterboxLocalizedString(@"Next", @"For continuous playback, introductory label for content which is about to start");
    introLabel.textAlignment = NSTextAlignmentCenter;
    introLabel.textColor = UIColor.lightGrayColor;
    [self.stackView addSubview:introLabel];
    self.introLabel = introLabel;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = UIColor.whiteColor;
    [self.stackView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.textColor = UIColor.lightGrayColor;
    [self.stackView addSubview:subtitleLabel];
    self.subtitleLabel = subtitleLabel;
    
    UIView *spacerView2 = [[UIView alloc] init];
    [self.stackView addSubview:spacerView2 withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 6.f;
    }];
    
    SRGStackView *horizontalStackView = [[SRGStackView alloc] init];
    horizontalStackView.direction = SRGStackViewDirectionHorizontal;
    [self.stackView addSubview:horizontalStackView];
    
    UIView *horizontalSpacerView1 = [[UIView alloc] init];
    [horizontalStackView addSubview:horizontalSpacerView1];
    
    SRGRemainingTimeButton *remainingTimeButton = [[SRGRemainingTimeButton alloc] init];
    remainingTimeButton.tintColor = UIColor.whiteColor;
    [remainingTimeButton setImage:[UIImage srg_letterboxCenteredPlayImage] forState:UIControlStateNormal];
    [remainingTimeButton addTarget:self action:@selector(playUpcomingMedia:) forControlEvents:UIControlEventTouchUpInside];
    [horizontalStackView addSubview:remainingTimeButton withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 55.f;
    }];
    self.remainingTimeButton = remainingTimeButton;
    
    UIView *horizontalSpacerView2 = [[UIView alloc] init];
    [horizontalStackView addSubview:horizontalSpacerView2];
    
    UIView *spacerView3 = [[UIView alloc] init];
    [self.stackView addSubview:spacerView3 withAttributes:^(SRGStackAttributes * _Nonnull attributes) {
        attributes.length = 6.f;
    }];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.titleLabel.textColor = UIColor.whiteColor;
    [cancelButton setTitle:SRGLetterboxLocalizedString(@"Cancel", @"Title of a cancel button") forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelContinuousPlayback:) forControlEvents:UIControlEventTouchUpInside];
    [self.stackView addSubview:cancelButton];
    self.cancelButton = cancelButton;
    
    UIView *spacerView4 = [[UIView alloc] init];
    [self.stackView addSubview:spacerView4];
}

- (void)contentSizeCategoryDidChange
{
    [super contentSizeCategoryDidChange];
    
    self.introLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.titleLabel.font = [UIFont srg_boldFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    self.cancelButton.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)willDetachFromController
{
    [super willDetachFromController];
    
    SRGLetterboxController *controller = self.controller;
    [controller removeObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia)];
}

- (void)didAttachToController
{
    [super didAttachToController];
    
    SRGLetterboxController *controller = self.controller;
    
    @weakify(self)
    [controller addObserver:self keyPath:@keypath(controller.continuousPlaybackUpcomingMedia) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self refresh];
        [self.parentLetterboxView setNeedsLayoutAnimated:YES];
    }];
    
    [self refresh];
    [self updateLayout];
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.alpha = (self.controller.continuousPlaybackUpcomingMedia) ? 1.f : 0.f;
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    [self updateLayout];
}

#pragma mark UI

- (void)refresh
{
    // Only update with valid upcoming information
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    if (upcomingMedia) {
        self.titleLabel.text = upcomingMedia.title;
        self.subtitleLabel.text = upcomingMedia.lead ?: upcomingMedia.summary;
        
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        
        [self.imageView srg_requestImageForObject:upcomingMedia withScale:SRGImageScaleLarge type:SRGImageTypeDefault];
        
        NSTimeInterval duration = [self.controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate];
        float progress = (duration != 0) ? ([NSDate.date timeIntervalSinceDate:self.controller.continuousPlaybackTransitionStartDate]) / duration : 1.f;
        [self.remainingTimeButton setProgress:progress withDuration:duration];
    }
}

- (void)updateLayout
{
    self.introLabel.hidden = NO;
    self.titleLabel.hidden = NO;
    self.subtitleLabel.hidden = NO;
    self.cancelButton.hidden = NO;
    self.remainingTimeButton.enabled = YES;
    
    if (self.controller.continuousPlaybackUpcomingMedia) {
        if (! self.parentLetterboxView.userInterfaceEnabled) {
            self.remainingTimeButton.enabled = NO;
            self.cancelButton.hidden = YES;
        }
        
        CGFloat height = CGRectGetHeight(self.frame);
        if (height < 200.f) {
            self.introLabel.hidden = YES;
            self.subtitleLabel.hidden = YES;
        }
        if (height < 150.f) {
            self.cancelButton.hidden = YES;
        }
        if (height < 100.f) {
            self.titleLabel.hidden = YES;
        }
    }
}

#pragma mark Actions

- (void)cancelContinuousPlayback:(id)sender
{
    // Save media informations since cancelling will change it
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    [self.controller cancelContinuousPlayback];
    [self.delegate continuousPlaybackView:self didCancelWithUpcomingMedia:upcomingMedia];
}

- (void)playUpcomingMedia:(id)sender
{
    // Save media information since playing will change it
    SRGMedia *upcomingMedia = self.controller.continuousPlaybackUpcomingMedia;
    if ([self.controller playUpcomingMedia]) {
        [self.delegate continuousPlaybackView:self didEngageWithUpcomingMedia:upcomingMedia];
    }
}

@end
