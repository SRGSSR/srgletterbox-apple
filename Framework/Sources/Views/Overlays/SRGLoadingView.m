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

- (void)updateLayoutForUserInterfaceHidden:(BOOL)userInterfaceHidden
{
    [super updateLayoutForUserInterfaceHidden:userInterfaceHidden];
    
    if (self.controller.loading) {
        self.alpha = 1.f;
        [self.loadingImageView startAnimating];
    }
    else {
        self.alpha = 0.f;
        [self.loadingImageView stopAnimating];
    }
}

@end
