//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIView+SRGLetterbox.h"

@implementation UIView (SRGLetterbox)

- (void)srg_letterboxSetShadowHidden:(BOOL)hidden
{
    self.layer.shadowOpacity = hidden ? 0.f : 0.8f;
    self.layer.shadowRadius = 1.f;
    self.layer.shadowOffset = CGSizeMake(0.f, 1.f);
}

@end
