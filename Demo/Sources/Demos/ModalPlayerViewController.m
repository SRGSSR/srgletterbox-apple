//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalPlayerViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

@interface ModalPlayerViewController ()

@property (nonatomic, copy) NSString *uid;

@end

@implementation ModalPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithUid:(NSString *)uid
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    ModalPlayerViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.uid = uid;
    return viewController;
}

- (instancetype)init
{
    return [self initWithUid:nil];
}

#pragma mark View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        if (self.uid) {
            [[[SRGDataProvider currentDataProvider] videosWithUids:@[self.uid] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
                SRGMedia *media = medias.firstObject;
                [[SRGLetterboxService sharedService] playMedia:media
                                              preferredQuality:SRGQualityHD];
            }] resume];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        SRGLetterboxService *service = [SRGLetterboxService sharedService];
        if (! service.pictureInPictureActive) {
            [service reset];
        }
    }
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
