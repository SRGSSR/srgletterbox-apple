//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGAccessibilityView.h"

#import "NSBundle+SRGLetterbox.h"
#import "SRGLetterboxBaseView+Subclassing.h"
#import "SRGLetterboxView+Private.h"

@implementation SRGAccessibilityView

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
    if (self.accessibilityFrameView) {
        return UIAccessibilityConvertFrameToScreenCoordinates(self.accessibilityFrameView.bounds, self.accessibilityFrameView);
    }
    else {
        return [super accessibilityFrame];
    }
}

- (CGPoint)accessibilityActivationPoint
{
    CGRect frame = UIAccessibilityConvertFrameToScreenCoordinates(self.bounds, self);
    return CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
}

@end

#endif
