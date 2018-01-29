//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGCountdownView.h"

#import "NSBundle+SRGLetterbox.h"

#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

static void commonInit(SRGCountdownView *self);

@interface SRGCountdownView ()

@property (nonatomic, weak) IBOutlet UILabel *days1Label;
@property (nonatomic, weak) IBOutlet UILabel *days0Label;
@property (nonatomic, weak) IBOutlet UILabel *daysTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *hours1Label;
@property (nonatomic, weak) IBOutlet UILabel *hours0Label;
@property (nonatomic, weak) IBOutlet UILabel *hoursTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *minutes1Label;
@property (nonatomic, weak) IBOutlet UILabel *minutes0Label;
@property (nonatomic, weak) IBOutlet UILabel *minutesTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *seconds1Label;
@property (nonatomic, weak) IBOutlet UILabel *seconds0Label;
@property (nonatomic, weak) IBOutlet UILabel *secondsTitleLabel;

@end

@implementation SRGCountdownView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
        
        // The top-level view loaded from the xib file and initialized in `commonInit` is NOT an SRGLetterboxView. Manually
        // calling `-awakeFromNib` forces the final view initialization (also see comments in `commonInit`).
        [self awakeFromNib];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self updateFonts];
}

#pragma mark Fonts

- (void)updateFonts
{
    self.days1Label.font = [UIFont srg_boldFontWithSize:self.days1Label.font.pointSize];
    self.days0Label.font = [UIFont srg_boldFontWithSize:self.days0Label.font.pointSize];
    
    self.hours1Label.font = [UIFont srg_boldFontWithSize:self.hours1Label.font.pointSize];
    self.hours0Label.font = [UIFont srg_boldFontWithSize:self.hours0Label.font.pointSize];
    
    self.minutes1Label.font = [UIFont srg_boldFontWithSize:self.minutes1Label.font.pointSize];
    self.minutes0Label.font = [UIFont srg_boldFontWithSize:self.minutes0Label.font.pointSize];
    
    self.seconds1Label.font = [UIFont srg_boldFontWithSize:self.seconds1Label.font.pointSize];
    self.seconds0Label.font = [UIFont srg_boldFontWithSize:self.seconds0Label.font.pointSize];
}

@end

static void commonInit(SRGCountdownView *self)
{
    // This makes design in a xib and Interface Builder preview (IB_DESIGNABLE) work. The top-level view must NOT be
    // an SRGCountdownView to avoid infinite recursion
    UIView *view = [[[NSBundle srg_letterboxBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [self addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}
