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

#pragma mark Players

- (void)openSimplePlayerWithURNString:(NSString *)URNString
{
    SRGMediaURN *URN = URNString ? [SRGMediaURN mediaURNWithString:URNString] : nil;
    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
    [self.navigationController pushViewController:playerViewController animated:YES];
}

- (void)openModalPlayerWithURNString:(NSString *)URNString
{
    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:URNString];
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)openStandalonePlayerWithURNString:(NSString *)URNString
{
    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:URNString];
    StandalonePlayerViewController *playerViewController = [[StandalonePlayerViewController alloc] initWithURN:URN];
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)openMultiPlayerWithURNString:(NSString *)URNString URNString1:(NSString *)URNString1 URNString2:(NSString *)URNString2
{
    SRGMediaURN *URN = URNString ? [SRGMediaURN mediaURNWithString:URNString] : nil;
    SRGMediaURN *URN1 = URNString1 ? [SRGMediaURN mediaURNWithString:URNString1] : nil;
    SRGMediaURN *URN2 = URNString2 ? [SRGMediaURN mediaURNWithString:URNString2] : nil;
    
    MultiPlayerViewController *playerViewController = [[MultiPlayerViewController alloc] initWithURN:URN URN1:URN1 URN2:URN2 userInterfaceAlwaysHidden:YES];
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)openCustomURNEntryAlertWithCompletionBlock:(void (^)(NSString * _Nullable URNString))completionBlock
{
    NSParameterAssert(completionBlock);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter a media URN", nil)
                                                                             message:NSLocalizedString(@"The media will be played with the advanced player.\nFormat: urn:[BU]:[video|audio]:[uid]", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"urn:swi:video:41981254";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Play", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completionBlock(alertController.textFields.firstObject.text);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        // Basic player
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    [self openSimplePlayerWithURNString:@"urn:swi:video:41981254"];
                    break;
                }
                    
                case 1: {
                    [self openSimplePlayerWithURNString:@"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25"];
                    break;
                }
                    
                case 2: {
                    [self openSimplePlayerWithURNString:@"urn:rts:video:8368368"];
                    break;
                }
                    
                case 3: {
                    [self openSimplePlayerWithURNString:@"urn:srf:video:40ca0277-0e53-4312-83e2-4710354ff53e"];
                    break;
                }
                    
                case 4: {
                    [self openSimplePlayerWithURNString:@"urn:swi:video:1234567"];
                    break;
                }
                    
                case 5: {
                    [self openSimplePlayerWithURNString:nil];
                    break;
                }
                    
                case 6: {
                    [self openSimplePlayerWithURNString:@"urn:rts:video:1967124"];
                    break;
                }
                    
                case 7: {
                    [self openSimplePlayerWithURNString:@"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0"];
                    break;
                }
                    
                case 8: {
                    [self openSimplePlayerWithURNString:@"urn:rtr:audio:a029e818-77a5-4c2e-ad70-d573bb865e31"];
                    break;
                }
                    
                case 9: {
                    [self openSimplePlayerWithURNString:@"urn:rts:audio:8385103"];
                    break;
                }
                    
                case 10: {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                        [self openSimplePlayerWithURNString:URNString];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
        
        //Advanced player
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self openModalPlayerWithURNString:@"urn:swi:video:41981254"];
                    break;
                }
                    
                case 1: {
                    [self openModalPlayerWithURNString:@"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25"];
                    break;
                }
                    
                case 2: {
                    [self openModalPlayerWithURNString:@"urn:rts:video:8368368"];
                    break;
                }
                    
                case 3: {
                    [self openModalPlayerWithURNString:@"urn:swi:video:1234567"];
                    break;
                }
                    
                case 4: {
                    [self openModalPlayerWithURNString:nil];
                    break;
                }
                    
                case 5: {
                    [self openModalPlayerWithURNString:@"urn:rts:audio:8385103"];
                    break;
                }
                    
                case 6: {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                        [self openModalPlayerWithURNString:URNString];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
        
        // Standalone player
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    [self openStandalonePlayerWithURNString:@"urn:swi:video:41981254"];
                    break;
                }
                    
                case 1: {
                    [self openStandalonePlayerWithURNString:@"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25"];
                    break;
                }
                    
                case 2: {
                    [self openStandalonePlayerWithURNString:@"urn:rts:video:8368368"];
                    break;
                }
                    
                case 3: {
                    [self openStandalonePlayerWithURNString:@"urn:swi:video:1234567"];
                    break;
                }
                    
                case 4: {
                    [self openStandalonePlayerWithURNString:nil];
                    break;
                }
                    
                case 5: {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URNString) {
                        [self openStandalonePlayerWithURNString:URNString];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
        
        // Segments player
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    [self openModalPlayerWithURNString:@"urn:rts:video:8412757"];
                    break;
                }
                    
                case 1: {
                    [self openModalPlayerWithURNString:@"urn:rts:video:8412759"];
                    break;
                }
                    
                case 2: {
                    [self openModalPlayerWithURNString:@"urn:rts:audio:8399352"];
                    break;
                }
                    
                case 3: {
                    [self openModalPlayerWithURNString:@"urn:rts:audio:8399354"];
                    break;
                }
                
                case 4: {
                    [self openModalPlayerWithURNString:@"urn:rts:video:8414189,8419195"];
                    break;
                }
                    
                default: {                    
                    break;
                }
            }
            break;
        }
        
        // Multiple player
        case 4: {
            switch (indexPath.row) {
                case 0: {
                    [self openMultiPlayerWithURNString:@"urn:rts:video:3608506" URNString1:@"urn:rts:video:3608517" URNString2:@"urn:rts:video:1967124"];
                    break;
                }
                    
                case 1: {
                    [self openMultiPlayerWithURNString:@"urn:swi:video:41981254" URNString1:@"urn:rts:video:8412757" URNString2:@"urn:rts:video:1967124"];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
        
        // Autoplay
        case 5: {
            AutoplayViewController *autoplayViewController = [[AutoplayViewController alloc] init];
            [self.navigationController pushViewController:autoplayViewController animated:YES];
        }
            
        default: {
            break;
        }
    }
}

@end
