//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLoadingView.h"

#import "UIImageView+SRGLetterbox.h"
#import "SRGLetterboxControllerView+Subclassing.h"

#import <Masonry/Masonry.h>

@interface SRGLoadingView ()

@property (nonatomic, weak) IBOutlet UIView *dimmingView;
@property (nonatomic, weak) UIImageView *loadingImageView;

@end

@implementation SRGLoadingView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIImageView *loadingImageView = [UIImageView srg_loadingImageView48WithTintColor:[UIColor whiteColor]];
    [self addSubview:loadingImageView];
    [loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
    }];
    self.loadingImageView = loadingImageView;
}

- (void)immediatelyUpdateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super immediatelyUpdateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.dimmingView.hidden = ! userInterfaceHidden;
    
    if (self.controller.loading) {
        [self.loadingImageView startAnimating];
    }
    else {
        [self.loadingImageView stopAnimating];
    }
}

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    self.alpha = self.controller.loading ? 1.f : 0.f;
}

@end
