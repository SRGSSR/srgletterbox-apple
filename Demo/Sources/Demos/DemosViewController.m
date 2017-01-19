//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "ModalPlayerViewController.h"
#import "SimplePlayerViewController.h"

@implementation DemosViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return @"Letterbox demos";
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: {
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] init];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 1: {
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] init];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        default: {
            break;
        }
    }
}

@end
