//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxPlaybackButton.h"

#import "UIImage+SRGLetterbox.h"
#import "NSBundle+SRGLetterbox.h"

static void commonInit(SRGLetterboxPlaybackButton *self);

@implementation SRGLetterboxPlaybackButton

@synthesize useStopImage = _useStopImage;
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

- (void)setUseStopImage:(BOOL)useStopImage
{
    _useStopImage = useStopImage;
    
    self.pauseImage = (useStopImage) ? [UIImage srg_letterboxStopImageInSet:self.imageSet] : [UIImage srg_letterboxPauseImageInSet:self.imageSet];
}

- (void)setImageSet:(SRGImageSet)imageSet
{
    _imageSet = imageSet;
    
    self.playImage = [UIImage srg_letterboxPlayImageInSet:imageSet];
    self.pauseImage = (self.useStopImage) ? [UIImage srg_letterboxStopImageInSet:imageSet] : [UIImage srg_letterboxPauseImageInSet:imageSet];
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    if (self.playbackButtonState == SRGPlaybackButtonStatePause && self.useStopImage) {
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


