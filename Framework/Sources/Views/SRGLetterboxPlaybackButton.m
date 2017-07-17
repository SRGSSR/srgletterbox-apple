//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxPlaybackButton.h"

#import "NSBundle+SRGLetterbox.h"
#import "UIImage+SRGLetterbox.h"

static void commonInit(SRGLetterboxPlaybackButton *self);

@implementation SRGLetterboxPlaybackButton

@synthesize usesStopImage = _usesStopImage;
@synthesize imageSet = _imageSet;

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)setUsesStopImage:(BOOL)usesStopImage
{
    _usesStopImage = usesStopImage;
    
    self.pauseImage = (usesStopImage) ? [UIImage srg_letterboxStopImageInSet:self.imageSet] : [UIImage srg_letterboxPauseImageInSet:self.imageSet];
}

- (void)setImageSet:(SRGImageSet)imageSet
{
    _imageSet = imageSet;
    
    self.playImage = [UIImage srg_letterboxPlayImageInSet:imageSet];
    self.pauseImage = (self.usesStopImage) ? [UIImage srg_letterboxStopImageInSet:imageSet] : [UIImage srg_letterboxPauseImageInSet:imageSet];
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    if (self.playbackButtonState == SRGPlaybackButtonStatePause && self.usesStopImage) {
        return SRGLetterboxAccessibilityLocalizedString(@"Stop", @"Stop button label");
    }
    else {
        return [super accessibilityLabel];
    }
}

@end

#pragma mark Functions

static void commonInit(SRGLetterboxPlaybackButton *self)
{
    self.imageSet = SRGImageSetNormal;
}
