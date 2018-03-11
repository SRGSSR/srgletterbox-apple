//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSubdivisionCell.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGPaddedLabel.h"
#import "UIImageView+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGLetterboxSubdivisionCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet SRGPaddedLabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIImageView *favoriteImageView;
@property (nonatomic, weak) IBOutlet UIImageView *media360ImageView;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UIImageView *blockingReasonImageView;

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
    UIImage *media360Image = self.media360ImageView.image;
    self.media360ImageView.image = nil;
    self.media360ImageView.image = media360Image;
    
    UIImage *favoriteImage = self.favoriteImageView.image;
    self.favoriteImageView.image = nil;
    self.favoriteImageView.image = favoriteImage;
    
    self.favoriteImageView.backgroundColor = [UIColor srg_redColor];
    self.favoriteImageView.hidden = YES;
    
    self.durationLabel.horizontalMargin = 5.f;
    
    self.blockingOverlayView.hidden = YES;
    
    // Workaround UIImage view tint color bug
    // See http://stackoverflow.com/a/26042893/760435
    UIImage *blockingReasonImage = self.blockingReasonImageView.image;
    self.blockingReasonImageView.image = nil;
    self.blockingReasonImageView.image = blockingReasonImage;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.favoriteImageView.hidden = YES;
    self.blockingOverlayView.hidden = YES;
    
    self.blockingReasonImageView.image = nil;
    
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
    
    SRGTimeAvailability timeAvailability = [subdivision timeAvailabilityAtDate:[NSDate date]];
    if (timeAvailability == SRGTimeAvailabilityNotYetAvailable) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Soon", @"Short label identifying content which will be available soon.").uppercaseString;
        self.durationLabel.hidden = NO;
    }
    else if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Expired", @"Short label identifying content which has expired.").uppercaseString;
        self.durationLabel.hidden = NO;
    }
    else if (subdivision.contentType == SRGContentTypeLivestream || subdivision.contentType == SRGContentTypeScheduledLivestream) {
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Live", @"Short label identifying a livestream or currently in live condition.").uppercaseString
                                                                                           attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                                         NSForegroundColorAttributeName : [UIColor whiteColor] }];
        
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:SRGLetterboxNonLocalizedString(@" ●")
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
        self.durationLabel.text = durationString;
        self.durationLabel.hidden = NO;
    }
    else {
        self.durationLabel.text = nil;
        self.durationLabel.hidden = YES;
    }
    
    SRGBlockingReason blockingReason = [subdivision blockingReasonAtDate:[NSDate date]];
    if (blockingReason == SRGBlockingReasonNone || blockingReason == SRGBlockingReasonStartDate) {
        self.blockingOverlayView.hidden = YES;
        self.blockingReasonImageView.image = nil;
        
        self.titleLabel.textColor = [UIColor whiteColor];
    }
    else {
        self.blockingOverlayView.hidden = NO;
        self.blockingReasonImageView.image = [UIImage srg_letterboxImageForBlockingReason:blockingReason];
        
        self.titleLabel.textColor = [UIColor lightGrayColor];
    }
    
    self.favoriteImageView.hidden = ! self.delegate || ! [self.delegate letterboxSubdivisionCellShouldDisplayFavoriteIcon:self];
    
    SRGPresentation presentation = SRGPresentationDefault;
    if ([subdivision isKindOfClass:SRGChapter.class]) {
        presentation = ((SRGChapter *)subdivision).presentation;
    }
    self.media360ImageView.hidden = (presentation != SRGPresentation360);
}

- (void)setProgress:(float)progress
{
    self.progressView.progress = progress;
}

- (void)setCurrent:(BOOL)current
{
    _current = current;
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
