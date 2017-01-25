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
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:41981254"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 1: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 2: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:41981254"];
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 3: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:42844052"];
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
        case 4: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:srf:ais:video:db741834-044f-443e-901a-e2fc03a4ef25"];
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        default: {
            break;
        }
    }
}

@end
