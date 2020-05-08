//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxSubdivisionCell.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSDateComponentsFormatter+SRGLetterbox.h"
#import "SRGPaddedLabel.h"
#import "UIColor+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SRGLetterboxSubdivisionCell ()

@property (nonatomic, weak) IBOutlet UIView *wrapperView;

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet SRGPaddedLabel *durationLabel;
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
    
    self.media360ImageView.layer.shadowOpacity = 0.3f;
    self.media360ImageView.layer.shadowRadius = 2.f;
    self.media360ImageView.layer.shadowOffset = CGSizeMake(0.f, 1.f);
    
    self.durationLabel.horizontalMargin = 5.f;
    self.durationLabel.layer.cornerRadius = 3.f;
    self.durationLabel.layer.masksToBounds = YES;
    
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
    self.durationLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    
    SRGTimeAvailability timeAvailability = [subdivision timeAvailabilityAtDate:NSDate.date];
    if (timeAvailability == SRGTimeAvailabilityNotYetAvailable) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Soon", @"Short label identifying content which will be available soon.").uppercaseString;
        self.durationLabel.hidden = NO;
    }
    else if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Expired", @"Short label identifying content which has expired.").uppercaseString;
        self.durationLabel.hidden = NO;
    }
    else if (subdivision.contentType == SRGContentTypeLivestream || subdivision.contentType == SRGContentTypeScheduledLivestream) {
        self.durationLabel.text = SRGLetterboxLocalizedString(@"Live", @"Short label identifying a livestream. Display in uppercase.").uppercaseString;
        self.durationLabel.hidden = NO;
        self.durationLabel.backgroundColor = UIColor.srg_liveRedColor;
    }
    else if (subdivision.duration != 0.) {
        NSTimeInterval durationInSeconds = subdivision.duration / 1000.;
        if (durationInSeconds <= 60. * 60.) {
            self.durationLabel.text = [NSDateComponentsFormatter.srg_shortDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
        }
        else {
            self.durationLabel.text = [NSDateComponentsFormatter.srg_mediumDateComponentsFormatter stringFromTimeInterval:durationInSeconds];
        }
        self.durationLabel.hidden = NO;
    }
    else {
        self.durationLabel.text = nil;
        self.durationLabel.hidden = YES;
    }
    
    SRGBlockingReason blockingReason = [subdivision blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonNone || blockingReason == SRGBlockingReasonStartDate) {
        self.blockingOverlayView.hidden = YES;
        self.blockingReasonImageView.image = nil;
        
        self.titleLabel.textColor = UIColor.whiteColor;
    }
    else {
        self.blockingOverlayView.hidden = NO;
        self.blockingReasonImageView.image = [UIImage srg_letterboxImageForBlockingReason:blockingReason];
        
        self.titleLabel.textColor = UIColor.lightGrayColor;
    }
    
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
    
    if (current) {
        self.contentView.layer.cornerRadius = 4.f;
        self.contentView.layer.masksToBounds = YES;
        self.contentView.backgroundColor = [UIColor colorWithRed:128.f / 255.f green:0.f / 255.f blue:0.f / 255.f alpha:1.f];
        
        self.wrapperView.layer.cornerRadius = 0.f;
        self.wrapperView.layer.masksToBounds = NO;
    }
    else {
        self.contentView.layer.cornerRadius = 0.f;
        self.contentView.layer.masksToBounds = NO;
        self.contentView.backgroundColor = UIColor.clearColor;
        
        self.wrapperView.layer.cornerRadius = 4.f;
        self.wrapperView.layer.masksToBounds = YES;
    }
}

#pragma mark Gesture recognizers

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.delegate) {
            [self.delegate letterboxSubdivisionCellDidLongPress:self];
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
