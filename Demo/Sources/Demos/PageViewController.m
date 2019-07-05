//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PageViewController.h"

#import "PlayerPageViewController.h"

@interface PageViewController ()

@property (nonatomic) NSArray<NSString *> *URNs;
@property (nonatomic) NSUInteger currentIndex;

@end

@implementation PageViewController

#pragma mark Object lifecycle

- (instancetype)initWithURNs:(NSArray<NSString *> *)URNs
{
    NSAssert(URNs.count > 0, @"At least one URN must be provided");
    
    if (self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil]) {
        self.URNs = URNs;
        self.currentIndex = 0;
        
        // Scrolls only if there is a need to
        if (URNs.count > 1) {
            self.dataSource = self;
        }
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PlayerPageViewController *viewController = [[PlayerPageViewController alloc] initWithURN:self.URNs.firstObject];
    [self setViewControllers:@[ viewController ] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

#pragma mark UIPageViewControllerDataSource protocol

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(PlayerPageViewController *)viewController
{
    NSUInteger index = [self.URNs indexOfObject:viewController.URN];
    NSString *URN = (index > 0) ? self.URNs[index - 1] : self.URNs.lastObject;
    return [[PlayerPageViewController alloc] initWithURN:URN];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(PlayerPageViewController *)viewController
{
    NSUInteger index = [self.URNs indexOfObject:viewController.URN];
    NSString *URN = (index < self.URNs.count - 1) ? self.URNs[index + 1] : self.URNs.firstObject;
    return [[PlayerPageViewController alloc] initWithURN:URN];
}

@end
