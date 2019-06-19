//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGControlsBackgroundView.h"

#import "UIImageView+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"

#import <Masonry/Masonry.h>

@interface SRGControlsBackgroundView ()

@property (nonatomic, weak) IBOutlet UIView *dimmingView;
@property (nonatomic, weak) UIImageView *loadingImageView;

@end

@implementation SRGControlsBackgroundView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Disable all user interactions so that the view does not trap gesture recognizers. Its only purpose is
    // to increase control readability and displaying the activity indicator
    self.userInteractionEnabled = NO;
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.dimmingView.alpha = (! userInterfaceHidden || self.controller.loading) ? 1.f : 0.f;
    
    if (self.controller.loading) {
        self.loadingImageView.alpha = 1.f;
        [self.loadingImageView startAnimating];
    }
    else {
        self.loadingImageView.alpha = 0.f;
        [self.loadingImageView stopAnimating];
    }
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    // Lazily add view when needed, mitigating associated costs
    if (self.controller.loading && ! self.loadingImageView) {
        UIImageView *loadingImageView = [UIImageView srg_loadingImageView48WithTintColor:UIColor.whiteColor];
        loadingImageView.alpha = 0.f;
        [self addSubview:loadingImageView];
        
        [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_centerX);
            make.centerY.equalTo(self.mas_centerY);
        }];
        
        self.loadingImageView = loadingImageView;
    }
}

@end
