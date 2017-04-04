//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlsView.h"

@implementation SRGControlsView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.delegate controlsViewDidLayoutSubviews:self];
}

@end
