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

@interface DemosViewController ()

@property (nonatomic) SRGDataProvider *dataProvider;
@property (nonatomic, weak) SRGRequest *request;

@end

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
    
    return [NSString stringWithFormat:@"Letterbox %@ demos (build %@)", versionString, bundleVersion];
}

#pragma mark Players

- (void)openSimplePlayerWithURNString:(NSString *)URNString
{
    SRGMediaURN *URN = URNString ? [SRGMediaURN mediaURNWithString:URNString] : nil;
    SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithURN:URN];
    [self.navigationController pushViewController:playerViewController animated:YES];
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

- (void)openModalPlayerWithURNString:(NSString *)URNString
{
    SRGMediaURN *URN = URNString ? [SRGMediaURN mediaURNWithString:URNString] : nil;
    ModalPlayerViewController *playerViewController = [[ModalPlayerViewController alloc] initWithURN:URN];
    
    // Since might be reused, ensure we are not trying to present the same view controller while still dismissed
    // (might happen if presenting and dismissing fast)
    if (playerViewController.presentingViewController) {
        return;
    }
    
    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)openModalPlayerWithLatestLiveCenterVideoForBusinessUnitIdentifier:(SRGDataProviderBusinessUnitIdentifier)dataProviderBusinessUnitIdentifier
{
    [self.request cancel];
    
    self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL() businessUnitIdentifier:dataProviderBusinessUnitIdentifier];
    SRGRequest *request =  [self.dataProvider liveCenterVideosWithCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSError * _Nullable error) {
        [self openModalPlayerWithURNString:medias.firstObject.URN.URNString];
    }];
    [request resume];
    self.request = request;
}

- (void)openMultiPlayerWithURNString:(nullable NSString *)URNString URNString1:(nullable NSString *)URNString1 URNString2:(nullable NSString *)URNString2
{
    SRGMediaURN *URN = (URNString) ? [SRGMediaURN mediaURNWithString:URNString] : nil;
    SRGMediaURN *URN1 = (URNString1) ? [SRGMediaURN mediaURNWithString:URNString1] : nil;
    SRGMediaURN *URN2 = (URNString2) ? [SRGMediaURN mediaURNWithString:URNString2] : nil;
    
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
        textField.placeholder = NSLocalizedString(@"urn:swi:video:41981254", nil);
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Play", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completionBlock(alertController.textFields.firstObject.text);
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kVideoOnDemandURNString = @"urn:swi:video:41981254";
    static NSString * const kVideoOnDemandShortClipURNString = @"urn:rts:video:8591082";
    static NSString * const kVideoOnDemandSegmentsURNString = @"urn:rts:video:8412757";
    static NSString * const kVideoOnDemandStartOnSegmentURNString = @"urn:rts:video:8412759";
    static NSString * const kVideoOnDemandWithNoFullLengthURNString = @"urn:rts:video:8686071";
    static NSString * const kVideoOnDemandBlockedSegmentURNString = @"urn:srf:video:40ca0277-0e53-4312-83e2-4710354ff53e";
    static NSString * const kVideoOnDemandBlockedSegmentOverlapURNString = @"urn:srf:video:d57f5c1c-080f-49a2-864e-4a1a83e41ae1";
    static NSString * const kVideoOnDemandHybridURNString = @"urn:rts:audio:8581974";
    static NSString * const kVideoOnDemandNoTokenURNString = @"urn:srf:video:db741834-044f-443e-901a-e2fc03a4ef25";
    
    static NSString * const kVideoDVRURNString = @"urn:rts:video:1967124";
    static NSString * const kVideoLiveURNString = @"urn:srf:video:c49c1d73-2f70-0001-138a-15e0c4ccd3d0";
    
    static NSString * const kAudioOnDemandSegmentsURNString = @"urn:rts:audio:8399352";
    static NSString * const kAudioOnDemandStartOnSegmentURNString = @"urn:rts:audio:8399354";
    static NSString * const kAudioDVRURNString = @"urn:rts:audio:3262363";
    static NSString * const kAudioDVRRegionalURNString = @"urn:srf:audio:5e266ba0-f769-4d6d-bd41-e01f188dd106";
    
    static NSString * const kInvalidURNString = @"urn:swi:video:1234567";
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    [self openSimplePlayerWithURNString:kVideoOnDemandURNString];
                    break;
                }
                    
                case 1: {
                    [self openSimplePlayerWithURNString:kVideoOnDemandSegmentsURNString];
                    break;
                }
                    
                case 2: {
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
            
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self openStandalonePlayerWithURNString:kVideoOnDemandURNString];
                    break;
                }
                    
                case 1: {
                    [self openStandalonePlayerWithURNString:kVideoOnDemandSegmentsURNString];
                    break;
                }
                    
                case 2: {
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
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    [self openModalPlayerWithURNString:kVideoOnDemandURNString];
                    break;
                }
                    
                case 1: {
                    [self openModalPlayerWithURNString:kVideoOnDemandShortClipURNString];
                    break;
                }
                    
                case 2: {
                    [self openModalPlayerWithURNString:kVideoOnDemandSegmentsURNString];
                    break;
                }
                    
                case 3: {
                    [self openModalPlayerWithURNString:kVideoOnDemandStartOnSegmentURNString];
                    break;
                }
                    
                case 4: {
                    [self openModalPlayerWithURNString:kVideoOnDemandWithNoFullLengthURNString];
                    break;
                }
                    
                case 5: {
                    [self openModalPlayerWithURNString:kVideoOnDemandBlockedSegmentURNString];
                    break;
                }
                    
                case 6: {
                    [self openModalPlayerWithURNString:kVideoOnDemandBlockedSegmentOverlapURNString];
                    break;
                }
                    
                case 7: {
                    [self openModalPlayerWithURNString:kVideoOnDemandHybridURNString];
                    break;
                }
                    
                case 8: {
                    [self openModalPlayerWithURNString:kVideoOnDemandNoTokenURNString];
                    break;
                }
                    
                case 9: {
                    [self openModalPlayerWithURNString:kVideoDVRURNString];
                    break;
                }
                    
                case 10: {
                    [self openModalPlayerWithURNString:kVideoLiveURNString];
                    break;
                }
                    
                case 11: {
                    [self openModalPlayerWithURNString:kAudioOnDemandSegmentsURNString];
                    break;
                }
                    
                case 12: {
                    [self openModalPlayerWithURNString:kAudioOnDemandStartOnSegmentURNString];
                    break;
                }
                    
                case 13: {
                    [self openModalPlayerWithURNString:kAudioDVRURNString];
                    break;
                }
                    
                case 14: {
                    [self openModalPlayerWithURNString:kAudioDVRRegionalURNString];
                    break;
                }
                    
                case 15: {
                    [self openModalPlayerWithLatestLiveCenterVideoForBusinessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
                    break;
                }
                    
                case 16: {
                    [self openModalPlayerWithLatestLiveCenterVideoForBusinessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRTS];
                    break;
                }
                    
                case 17: {
                    [self openModalPlayerWithLatestLiveCenterVideoForBusinessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRSI];
                    break;
                }
                    
                case 18: {
                    [self openModalPlayerWithURNString:kInvalidURNString];
                    break;
                }
                    
                case 19: {
                    [self openModalPlayerWithURNString:nil];
                    break;
                }
                    
                case 20: {
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
        
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    [self openMultiPlayerWithURNString:@"urn:rts:video:3608506" URNString1:@"urn:rts:video:3608517" URNString2:@"urn:rts:video:1967124"];
                    break;
                }
                    
                case 1: {
                    [self openMultiPlayerWithURNString:kVideoOnDemandURNString URNString1:kVideoOnDemandSegmentsURNString URNString2:kVideoDVRURNString];
                    break;
                }
                    
                case 2: {
                    [self openMultiPlayerWithURNString:@"urn:rts:video:3608517" URNString1:nil URNString2:@"urn:rts:video:1234567"];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
        
        case 4: {
            AutoplayList autoplayList = AutoplayListUnknown;
            switch (indexPath.row) {
                case 0: {
                    autoplayList = AutoplayListRTSTrendingMedias;
                    break;
                }
                    
                case 1: {
                    autoplayList = AutoplayListSRFLiveCenterVideos;
                    break;
                }
                    
                case 2: {
                    autoplayList = AutoplayListRTSLiveCenterVideos;
                    break;
                }
                    
                case 3: {
                    autoplayList = AutoplayListRSILiveCenterVideos;
                    break;
                }
                    
                default: {
                    break;
                }
            }
            
            AutoplayViewController *autoplayViewController = [[AutoplayViewController alloc] init];
            autoplayViewController.autoplayList = autoplayList;
            [self.navigationController pushViewController:autoplayViewController animated:YES];
        }
            
        default: {
            break;
        }
    }
}

@end
