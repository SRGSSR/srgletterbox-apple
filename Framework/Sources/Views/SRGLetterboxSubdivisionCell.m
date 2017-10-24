//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSubdivisionCell.h"

#import "NSBundle+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGLetterboxSubdivisionCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIImageView *favoriteImageView;
@property (nonatomic, weak) IBOutlet UIView *disabledView;

@property (nonatomic, weak) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@implementation SRGLetterboxSubdivisionCell

#pragma mark View life cycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(longPress:)];
    longPressGestureRecognizer.minimumPressDuration = 1.;
    [self addGestureRecognizer:longPressGestureRecognizer];
    self.longPressGestureRecognizer = longPressGestureRecognizer;
    
    // Workaround UIImage view tint color bug
    // See http://stackoverflow.com/a/26042893/760435
    UIImage *favoriteImage = self.favoriteImageView.image;
    self.favoriteImageView.image = nil;
    self.favoriteImageView.image = favoriteImage;
    
    self.disabledView.alpha = 0.f;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.imageView srg_resetImage];
}

#pragma mark Getters and setters

- (void)setSubdivision:(SRGSubdivision *)subdivision
{
    _subdivision = subdivision;
    
    self.titleLabel.text = subdivision.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    [self.imageView srg_requestImageForObject:subdivision withScale:SRGImageScaleMedium type:SRGImageTypeDefault];
    
    self.durationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    if (subdivision.blockingReason == SRGBlockingReasonStartDate) {
        self.durationLabel.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"Soon", @"Short label identifying content which will be available soon.").uppercaseString];
        self.durationLabel.hidden = NO;
    }
    else if (subdivision.blockingReason == SRGBlockingReasonEndDate) {
        self.durationLabel.text = [NSString stringWithFormat:@"  %@  ", SRGLetterboxLocalizedString(@"Expired", @"Short label identifying content which has expired.").uppercaseString];
        self.durationLabel.hidden = NO;
    }
    else if (subdivision.contentType == SRGContentTypeLivestream || subdivision.contentType == SRGContentTypeScheduledLivestream) {
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"Live", @"Short label identifying a livestream.")].uppercaseString
                                                                                           attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                                         NSForegroundColorAttributeName : [UIColor whiteColor] }];
        
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@"●  ")
                                                                               attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                             NSForegroundColorAttributeName : [UIColor redColor] }]];
        
        self.durationLabel.attributedText = attributedText.copy;
        self.durationLabel.hidden = NO;
    }
    else if (subdivision.duration != 0.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        
        NSString *durationString = [s_dateComponentsFormatter stringFromTimeInterval:subdivision.duration / 1000.];
        self.durationLabel.text = [NSString stringWithFormat:@"  %@  ", durationString];
        self.durationLabel.hidden = NO;
    }
    else {
        self.durationLabel.text = nil;
        self.durationLabel.hidden = YES;
    }
    
    self.disabledView.alpha = (subdivision.blockingReason != SRGBlockingReasonNone) ? 0.5f : 0.f;
    
    self.favoriteImageView.hidden = ! self.delegate || ! [self.delegate letterboxSubdivisionCellShouldDisplayFavoriteIcon:self];
}

- (void)setProgress:(float)progress
{
    self.progressView.progress = progress;
}

- (void)setCurrent:(BOOL)current
{
    self.backgroundColor = current ? [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f] : [UIColor blackColor];
}

#pragma mark Gesture recognizers

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.delegate) {
            [self.delegate letterboxSubdivisionCellDidLongPress:self];
            self.favoriteImageView.hidden = ! [self.delegate letterboxSubdivisionCellShouldDisplayFavoriteIcon:self];
        }
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.subdivision.title;
}

- (NSString *)accessibilityHint
{
    return SRGLetterboxAccessibilityLocalizedString(@"Plays the content.", @"Segment or chapter cell hint");
}

@end
