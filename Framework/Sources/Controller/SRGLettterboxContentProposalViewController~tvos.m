//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLettterboxContentProposalViewController.h"

#import "NSBundle+SRGLetterbox.h"
#import "NSTimer+SRGLetterbox.h"
#import "UIImageView+SRGLetterbox.h"

@interface SRGLettterboxContentProposalViewController ()

@property (nonatomic) SRGLetterboxController *controller;

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;

@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic) NSTimer *timer;

@end

@implementation SRGLettterboxContentProposalViewController

#pragma mark Object lifecycle

- (instancetype)initWithController:(SRGLetterboxController *)controller
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:SRGLetterboxResourceNameForUIClass(self.class) bundle:NSBundle.srg_letterboxBundle];
    SRGLettterboxContentProposalViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.controller = controller;
    return viewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithController:SRGLetterboxController.new];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (void)setTimer:(NSTimer *)timer
{
    [_timer invalidate];
    _timer = timer;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.movingToParentViewController || self.beingPresented) {
        self.timer = [NSTimer srgletterbox_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self reloadData];
        }];
        [self reloadData];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.movingFromParentViewController || self.beingDismissed) {
        self.timer = nil;
    }
}

#pragma mar UI

- (void)reloadData
{
    SRGMedia *nextMedia = self.controller.nextMedia;
    [self.thumbnailImageView srg_requestImageForObject:nextMedia withScale:SRGImageScaleMedium type:SRGImageTypeDefault];
    self.titleLabel.text = nextMedia.title;
    self.summaryLabel.text = nextMedia.summary;
    
    NSTimeInterval remainingTime = round([self.controller.continuousPlaybackTransitionEndDate timeIntervalSinceDate:NSDate.date]);
    self.remainingTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Starts in %@ seconds", nil), @(remainingTime)];
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
    [self dismissContentProposalForAction:AVContentProposalActionAccept animated:YES completion:^{
        self.playerViewController.contentProposalViewController = nil;
    }];
}

- (IBAction)cancel:(id)sender
{
    [self dismissContentProposalForAction:AVContentProposalActionReject animated:YES completion:^{
        self.playerViewController.contentProposalViewController = nil;
    }];
}

@end
