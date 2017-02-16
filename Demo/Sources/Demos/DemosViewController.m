//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "ModalPlayerViewController.h"
#import "MultiPlayerViewController.h"
#import "SimplePlayerViewController.h"
#import "StandalonePlayerViewController.h"

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
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 2: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:1234567"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 3: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:41981254"];
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 4: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25"];
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 5: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:1234567"];
            ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 6: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:41981254"];
            StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 7: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25"];
            StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 8: {
            MultiPlayerViewController *playerViewController = [[MultiPlayerViewController alloc] init];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 9: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:1967124"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 10: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        case 11: {
            SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rtr:audio:a029e818-77a5-4c2e-ad70-d573bb865e31"];
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
            [self.navigationController pushViewController:playerViewController animated:YES];
            break;
        }
            
        default: {
            break;
        }
    }
}

@end
