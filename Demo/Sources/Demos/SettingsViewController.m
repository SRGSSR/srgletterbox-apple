//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>

NSString * const LetterboxSRGSettingServiceDefaultURLString = @"https://il.srgssr.ch";
NSString * const LetterboxSRGSettingServiceURL = @"LetterboxSRGSettingServiceURL";

NSURL * ApplicationSettingServiceURL(void)
{
    NSString *urlString = ([[NSUserDefaults standardUserDefaults] stringForKey:LetterboxSRGSettingServiceURL]) ?: LetterboxSRGSettingServiceDefaultURLString;
    return [NSURL URLWithString:urlString] ?: [NSURL URLWithString:LetterboxSRGSettingServiceDefaultURLString];
}

@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet UITableViewCell *productionCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *stageCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *testCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *mmfCell;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"title of the settings view");
    [self reloadData];
}

- (void)reloadData {
    
    NSURL *serverURL = ApplicationSettingServiceURL();
    
    self.productionCell.accessoryType = [serverURL isEqual:SRGIntegrationLayerProductionServiceURL()] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.stageCell.accessoryType = [serverURL isEqual:SRGIntegrationLayerStagingServiceURL()] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.testCell.accessoryType = [serverURL isEqual:SRGIntegrationLayerTestServiceURL()] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    self.mmfCell.accessoryType = [serverURL isEqual:[NSURL URLWithString:@"https://play-mmf.herokuapp.com"]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *serverURL = ApplicationSettingServiceURL();
    switch (indexPath.row) {
        case 0:
            serverURL = SRGIntegrationLayerProductionServiceURL();
            break;
        case 1:
            serverURL = SRGIntegrationLayerStagingServiceURL();
            break;
        case 2:
            serverURL = SRGIntegrationLayerTestServiceURL();
            break;
        case 3:
            serverURL = [NSURL URLWithString:@"https://play-mmf.herokuapp.com"];
            break;
            
        default:
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:serverURL.absoluteString forKey:LetterboxSRGSettingServiceURL];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self reloadData];
}

@end
