//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SimplePlayerViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

@interface SimplePlayerViewController ()

@property (nonatomic) IBOutlet SRGLetterboxView *letterboxView;

@end

@implementation SimplePlayerViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[[SRGDataProvider currentDataProvider] videosWithUids:@[@"41981254"] completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSError * _Nullable error) {
        SRGMedia *media = medias.firstObject;
        [[SRGLetterboxService sharedService] playMedia:media
                                      withDataProvider:[SRGDataProvider currentDataProvider]
                                      preferredQuality:SRGQualityHD];
    }] resume];
}

@end
