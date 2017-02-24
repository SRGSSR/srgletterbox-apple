//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemosViewController.h"

#import "AutoplayViewController.h"
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
    NSString *versionString = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"];
    
#ifdef DEBUG
    versionString = [@"🛠 " stringByAppendingString:versionString];
#elif NIGHTLY
    versionString = [@"🌙 " stringByAppendingString:versionString];
#endif
    
    return [NSString stringWithFormat:@"Letterbox demos %@ (%@)", versionString, bundleVersion];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
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
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:8368368"];
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 3: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:1234567"];
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 4: {
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:nil];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 5: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:1967124"];
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 6: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0"];
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 7: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rtr:audio:a029e818-77a5-4c2e-ad70-d573bb865e31"];
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 8: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:audio:8385103"];
                    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                    [self.navigationController pushViewController:playerViewController animated:YES];
                    break;
                }
                    
                case 9: {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter the URN"
                                                                                             message:@"Will be played with the basic player.\nFormat: urn:[BU]:[video|audio]:[uid]"
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.placeholder = @"urn:swi:video:41981254";
                    }];
                    
                    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Open"
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction *action) {
                                                                              SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:alertController.textFields.firstObject.text];
                                                                              SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
                                                                              [self.navigationController pushViewController:playerViewController animated:YES];
                                                                          }];
                    
                    [alertController addAction:defaultAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 1: {
            switch (indexPath.row) {
                case 0: {
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
                    
                case 1: {
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
                    
                case 2: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:8368368"];
                    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
                    
                    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                    // (might happen if presenting and dismissing fast)
                    if (playerViewController.presentingViewController) {
                        return;
                    }
                    
                    [self presentViewController:playerViewController animated:YES completion:nil];
                    break;
                }
                    
                case 3: {
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
                    
                case 4: {
                    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:nil];
                    
                    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                    // (might happen if presenting and dismissing fast)
                    if (playerViewController.presentingViewController) {
                        return;
                    }
                    
                    [self presentViewController:playerViewController animated:YES completion:nil];
                    break;
                }
                    
                case 5: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:audio:8385103"];
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
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter the URN"
                                                                                             message:@"Will be played with the advanced player.\nFormat: urn:[BU]:[video|audio]:[uid]"
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.placeholder = @"urn:swi:video:41981254";
                    }];
                    
                    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Open"
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction *action) {
                                                                              SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:alertController.textFields.firstObject.text];
                                                                              ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
                                                                              
                                                                              // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                                                                              // (might happen if presenting and dismissing fast)
                                                                              if (playerViewController.presentingViewController) {
                                                                                  return;
                                                                              }
                                                                              
                                                                              [self presentViewController:playerViewController animated:YES completion:nil];
                                                                          }];
                    
                    [alertController addAction:defaultAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
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
                    
                case 1: {
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
                    
                case 2: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:rts:video:8368368"];
                    StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
                    
                    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                    // (might happen if presenting and dismissing fast)
                    if (playerViewController.presentingViewController) {
                        return;
                    }
                    [self presentViewController:playerViewController animated:YES completion:nil];
                    break;
                }
                    
                case 3: {
                    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:@"urn:swi:video:1234567"];
                    StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
                    
                    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                    // (might happen if presenting and dismissing fast)
                    if (playerViewController.presentingViewController) {
                        return;
                    }
                    [self presentViewController:playerViewController animated:YES completion:nil];
                    break;
                }
                    
                case 4: {
                    StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:nil];
                    
                    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                    // (might happen if presenting and dismissing fast)
                    if (playerViewController.presentingViewController) {
                        return;
                    }
                    [self presentViewController:playerViewController animated:YES completion:nil];
                    break;
                }
                    
                case 5: {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter the URN"
                                                                                             message:@"Will be played with the standalone player.\nFormat: urn:[BU]:[video|audio]:[uid]"
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.placeholder = @"urn:swi:video:41981254";
                    }];
                    
                    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Open"
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction *action) {
                                                                              SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:alertController.textFields.firstObject.text];
                                                                              StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
                                                                              
                                                                              // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
                                                                              // (might happen if presenting and dismissing fast)
                                                                              if (playerViewController.presentingViewController) {
                                                                                  return;
                                                                              }
                                                                              [self presentViewController:playerViewController animated:YES completion:nil];
                                                                          }];
                    
                    [alertController addAction:defaultAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 3: {
            MultiPlayerViewController *playerViewController = [[MultiPlayerViewController alloc] init];
            
            // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
            // (might happen if presenting and dismissing fast)
            if (playerViewController.presentingViewController) {
                return;
            }
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        case 4: {
            AutoplayViewController *autoplayViewController = [[AutoplayViewController alloc] init];
            [self.navigationController pushViewController:autoplayViewController animated:YES];
        }
            
        default: {
            break;
        }
    }
}

@end
