//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import "ServerSettings.h"

#import <HockeySDK/HockeySDK.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

NSString * const LetterboxDemoSettingServiceURL = @"LetterboxDemoSettingServiceURL";
NSString * const LetterboxDemoSettingAbroadSimulationEnabled = @"LetterboxDemoSettingAbroadSimulationEnabled";
NSString * const LetterboxDemoSettingStandalone = @"LetterboxDemoSettingStandalone";
NSString * const LetterboxDemoSettingMirroredOnExternalScreen = @"LetterboxDemoSettingMirroredOnExternalScreen";
NSString * const LetterboxDemoSettingUpdateInterval = @"LetterboxDemoSettingUpdateInterval";

NSTimeInterval const LetterboxDemoSettingUpdateIntervalShort = 10.;

NSURL *LetterboxDemoMMFServiceURL(void)
{
    NSString *serviceURLString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"PlayMMF"];
    NSURL *serviceURL = (serviceURLString.length > 0) ? [NSURL URLWithString:serviceURLString] : nil;
    return serviceURL ?: [NSURL URLWithString:@"https://play-mmf.herokuapp.com/integrationlayer"];
}

static void SettingServiceURLReset(void)
{
    BOOL settingServiceURLReset = [NSUserDefaults.standardUserDefaults boolForKey:@"SettingServiceURLReset"];
    if (! settingServiceURLReset) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:LetterboxDemoSettingServiceURL];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:LetterboxDemoSettingAbroadSimulationEnabled];
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"SettingServiceURLReset"];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

NSURL *ApplicationSettingServiceURL(void)
{
    SettingServiceURLReset();
    NSString *URLString = [NSUserDefaults.standardUserDefaults stringForKey:LetterboxDemoSettingServiceURL];
    return [NSURL URLWithString:URLString] ?: SRGIntegrationLayerProductionServiceURL();
}

static BOOL ApplicationSettingIsAbroadSimulationEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingAbroadSimulationEnabled];
}

static void ApplicationSettingSetAbroadSimulationEnabled(BOOL enabled)
{
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:LetterboxDemoSettingAbroadSimulationEnabled];
    [NSUserDefaults.standardUserDefaults synchronize];
}

BOOL ApplicationSettingIsStandalone(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingStandalone];
}

static void ApplicationSettingSetStandalone(BOOL standalone)
{
    [NSUserDefaults.standardUserDefaults setBool:standalone forKey:LetterboxDemoSettingStandalone];
    [NSUserDefaults.standardUserDefaults synchronize];
}

BOOL ApplicationSettingIsMirroredOnExternalScreen(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingMirroredOnExternalScreen];
}

void ApplicationSettingSetMirroredOnExternalScreen(BOOL mirroredOnExternalScreen)
{
    [NSUserDefaults.standardUserDefaults setBool:mirroredOnExternalScreen forKey:LetterboxDemoSettingMirroredOnExternalScreen];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    SRGLetterboxService.sharedService.mirroredOnExternalScreen = mirroredOnExternalScreen;
}

NSTimeInterval ApplicationSettingUpdateInterval(void)
{
    // Set manually to default value, 5 minutes, if no setting.
    NSTimeInterval updateInterval = [NSUserDefaults.standardUserDefaults doubleForKey:LetterboxDemoSettingUpdateInterval];
    return (updateInterval > 0.) ? updateInterval : SRGLetterboxDefaultUpdateInterval;
}

NSDictionary<NSString *, NSString *> *ApplicationSettingGlobalParameters(void)
{
    BOOL abroadSimulationEnabled = [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingAbroadSimulationEnabled];
    return abroadSimulationEnabled ? @{ @"forceLocation" : @"WW" } : nil;
}

@interface SettingsViewController ()

@property (nonatomic) NSArray<ServerSettings *> *serverSettings;

@end

@implementation SettingsViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    SettingsViewController *viewController = [storyboard instantiateInitialViewController];    
    viewController.serverSettings = @[[[ServerSettings alloc] initWithName:NSLocalizedString(@"Production", @"Server setting") URL:SRGIntegrationLayerProductionServiceURL()],
                                      [[ServerSettings alloc] initWithName:NSLocalizedString(@"Stage", @"Server setting") URL:SRGIntegrationLayerStagingServiceURL()],
                                      [[ServerSettings alloc] initWithName:NSLocalizedString(@"Test", @"Server setting") URL:SRGIntegrationLayerTestServiceURL()],
                                      [[ServerSettings alloc] initWithName:NSLocalizedString(@"Play MMF", @"Server setting") URL:LetterboxDemoMMFServiceURL()]];
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"Title of the settings view");
    
    [self.tableView reloadData];
}

#pragma mark Getters

- (BOOL)isCheckForUpdateButtonEnabled
{
    return ([BITHockeyManager sharedHockeyManager].updateManager != nil);
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return NSLocalizedString(@"Server", @"Server header title in settings view");
            break;
        }
            
        case 1: {
            return NSLocalizedString(@"User location", @"User location header title in settings view");
            break;
        }
            
        case 2: {
            return NSLocalizedString(@"Playback mode", @"Playback mode header title in settings view");
            break;
        }
            
        case 3: {
            return NSLocalizedString(@"Screen mirroring", @"Presentation mode header title in settings view");
            break;
        }
            
        case 4: {
            return NSLocalizedString(@"Control center integration", @"Control center integration title in settings view");
            break;
        }
            
        case 5: {
            return NSLocalizedString(@"Update interval", @"Update interval header title in settings view");
            break;
        }
            
        case 6: {
            NSString *buildNumberString = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"];
            return [NSString stringWithFormat:@"%@ (build %@)", NSLocalizedString(@"Application", @"Application header title in settings view"), buildNumberString];
            break;
        }
            
        default: {
            break;
        }
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        NSString *versionString = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];        
        return [NSString stringWithFormat:NSLocalizedString(@"This demo application presents SRG Letterbox features (version %@).\n\nIt is only intended for internal SRG SSR use and should not be distributed outside the company.", @"Warning footer in settings view"),
                versionString];
    }
    else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return self.serverSettings.count;
            break;
        }
            
        case 1:
        case 2:
        case 3:
        case 4:
        case 5: {
            return 2;
            break;
        }
            
        case 6: {
            return 1;
            break;
        }
            
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.userInteractionEnabled = YES;
    cell.textLabel.textColor = UIColor.blackColor;
    
    switch (indexPath.section) {
        case 0: {
            cell.textLabel.text = self.serverSettings[indexPath.row].name;
            
            NSURL *serverURL = ApplicationSettingServiceURL();
            cell.accessoryType = [serverURL isEqual:self.serverSettings[indexPath.row].URL] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
            
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Default (IP-based location)", @"Label for the defaut location mode setting");
                    cell.accessoryType = ! ApplicationSettingIsAbroadSimulationEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Outside CH", @"Label for the outside CH location mode setting");
                    cell.accessoryType = ApplicationSettingIsAbroadSimulationEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                default: {
                    cell.textLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                };
            }
            break;
        }
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Default (full-length)", @"Label for the defaut standalone mode disabled setting");
                    cell.accessoryType = ! ApplicationSettingIsStandalone() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Standalone", @"Label for the standalone mode enabled setting");
                    cell.accessoryType = ApplicationSettingIsStandalone() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                default: {
                    cell.textLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                };
            }
            break;
        }
            
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Disabled", @"Label for a disabled setting");
                    cell.accessoryType = ! ApplicationSettingIsMirroredOnExternalScreen() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", @"Label for an enabled setting");
                    cell.accessoryType = ApplicationSettingIsMirroredOnExternalScreen() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                default: {
                    cell.textLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                };
            }
            break;
        }
            
        case 4: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Disabled", @"Label for a disabled setting");
                    cell.accessoryType = ! SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", @"Label for an enabled setting");
                    cell.accessoryType = SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                default: {
                    cell.textLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                };
            }
            break;
        }
            
        case 5: {
            static NSDateComponentsFormatter *s_dateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
                s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
                s_dateComponentsFormatter.maximumUnitCount = 1;
            });
            
            switch (indexPath.row) {
                case 0: {
                    NSTimeInterval timeInterval = SRGLetterboxDefaultUpdateInterval;
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Default, every %@", @"Default update interval in settings view"), [s_dateComponentsFormatter stringFromTimeInterval:timeInterval]];
                    cell.accessoryType = (ApplicationSettingUpdateInterval() == timeInterval) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    NSTimeInterval timeInterval = LetterboxDemoSettingUpdateIntervalShort;
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Short, every %@", @"Short update interval in settings view"), [s_dateComponentsFormatter stringFromTimeInterval:timeInterval]];
                    cell.accessoryType = (ApplicationSettingUpdateInterval() == timeInterval) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                default: {
                    cell.textLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                };
            }
            break;
        }
            
        case 6: {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Check for updates", @"Check for updates button in settings view");
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = [self isCheckForUpdateButtonEnabled];
            cell.textLabel.textColor = [self isCheckForUpdateButtonEnabled] ? UIColor.blackColor : UIColor.lightGrayColor;
            break;
        }
            
        default: {
            cell.textLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    void (^completionBlock)(void) = nil;
    
    switch (indexPath.section) {
        case 0: {
            ServerSettings *serverSettings = self.serverSettings[indexPath.row];
            [NSUserDefaults.standardUserDefaults setObject:serverSettings.URL.absoluteString forKey:LetterboxDemoSettingServiceURL];
            [NSUserDefaults.standardUserDefaults synchronize];
            
            [SRGLetterboxService.sharedService.controller reset];
            SRGLetterboxService.sharedService.controller.serviceURL = ApplicationSettingServiceURL();
            break;
        }
            
        case 1: {
            ApplicationSettingSetAbroadSimulationEnabled(indexPath.row == 1);
            break;
        }
            
        case 2: {
            ApplicationSettingSetStandalone(indexPath.row == 1);
            break;
        }
            
        case 3: {
            ApplicationSettingSetMirroredOnExternalScreen(indexPath.row == 1);
            break;
        }
            
        case 4: {
            SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled = (indexPath.row == 1);
            break;
        }
            
        case 5: {
            if (indexPath.row == 0) {
                [NSUserDefaults.standardUserDefaults removeObjectForKey:LetterboxDemoSettingUpdateInterval];
            }
            else {
                [NSUserDefaults.standardUserDefaults setDouble:LetterboxDemoSettingUpdateIntervalShort forKey:LetterboxDemoSettingUpdateInterval];
            }
            [NSUserDefaults.standardUserDefaults synchronize];
            
            SRGLetterboxService.sharedService.controller.updateInterval = ApplicationSettingUpdateInterval();
            break;
        }
            
        case 6: {
            completionBlock = ^{
                [[BITHockeyManager sharedHockeyManager].updateManager showUpdateView];
            };
            break;
        }
            
        default: {
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView reloadData];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:completionBlock];
}

@end
