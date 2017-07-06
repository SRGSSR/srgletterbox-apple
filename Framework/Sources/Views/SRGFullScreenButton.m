//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGFullScreenButton.h"

#import "NSBundle+SRGLetterbox.h"

@implementation SRGFullScreenButton

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return self.selected ? SRGLetterboxAccessibilityLocalizedString(@"Exit full screen", @"Full screen button label in the letterbox view, when the view is in the full screen state") : SRGLetterboxAccessibilityLocalizedString(@"Full screen", @"Full screen button label in the letterbox view, when the view is NOT in the full screen state");
}

@end
