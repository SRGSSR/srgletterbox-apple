//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLettterboxContentProposalViewController.h"

#import "NSBundle+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

@interface SRGLettterboxContentProposalViewController ()

@property (nonatomic) SRGMedia *media;

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryLabel;

@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@end

@implementation SRGLettterboxContentProposalViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(SRGMedia *)media
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:SRGLetterboxResourceNameForUIClass(self.class) bundle:NSBundle.srg_letterboxBundle];
    SRGLettterboxContentProposalViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.media = media;
    return viewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithMedia:SRGMedia.new];
}

#pragma clang diagnostic pop

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO: Use a stack view for layout
    [self.thumbnailImageView srg_requestImageForObject:self.media withScale:SRGImageScaleMedium type:SRGImageTypeDefault];
    self.titleLabel.text = self.media.title;
    self.summaryLabel.text = self.media.summary;
}

#pragma mark Overrides

- (CGRect)preferredPlayerViewFrame
{
    static const CGFloat kWidth = 720.f;
    return CGRectMake(100.f, 100.f, kWidth, kWidth * 9.f / 16.f);
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return @[ self.nextButton ];
}

#pragma mark Actions

- (IBAction)playNext:(id)sender
{
    [self dismissContentProposalForAction:AVContentProposalActionAccept animated:YES completion:nil];
}

- (IBAction)cancel:(id)sender
{
    [self dismissContentProposalForAction:AVContentProposalActionReject animated:YES completion:nil];
}

@end
