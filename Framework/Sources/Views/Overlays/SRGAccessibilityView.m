//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAccessibilityView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxBaseView+Subclassing.h"
#import "SRGLetterboxView+Private.h"

@implementation SRGAccessibilityView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleUserInterface:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return (self.parentLetterboxView.controller.media.mediaType == SRGMediaTypeAudio) ? SRGLetterboxAccessibilityLocalizedString(@"Audio", @"The main area on the letterbox view, where the audio or its thumbnail is displayed") : SRGLetterboxAccessibilityLocalizedString(@"Video", @"The main area on the letterbox view, where the video or its thumbnail is displayed");
}

- (NSString *)accessibilityHint
{
    SRGLetterboxView *parentLetterboxView = self.parentLetterboxView;
    if (parentLetterboxView.userInterfaceBehavior == SRGLetterboxViewBehaviorNormal) {
        return parentLetterboxView.userInterfaceTogglable ? SRGLetterboxAccessibilityLocalizedString(@"Double tap to display or hide player controls.", @"Hint for the letterbox view") : nil;
    }
    else {
        return nil;
    }
}

- (CGRect)accessibilityFrame
{
    return UIAccessibilityConvertFrameToScreenCoordinates(self.parentLetterboxView.bounds, self.parentLetterboxView);
}

#pragma mark Actions

- (void)toggleUserInterface:(id)sender
{
    [self.parentLetterboxView setTogglableUserInterfaceHidden:! self.parentLetterboxView.userInterfaceHidden animated:YES];
}

@end
