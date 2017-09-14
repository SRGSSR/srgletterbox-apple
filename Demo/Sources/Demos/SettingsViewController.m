//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

NSString * const LetterboxSRGSettingServiceURL = @"LetterboxSRGSettingServiceURL";
NSString * const LetterboxSRGSettingMirroredOnExternalScreen = @"LetterboxSRGSettingMirroredOnExternalScreen";
NSString * const LetterboxSRGSettingStreamAvailabilityCheckInterval = @"LetterboxSRGSettingStreamAvailabilityCheckInterval";

NSTimeInterval const LetterboxSRGSettingStreamAvailabilityCheckIntervalShort = 10.;

NSURL *ApplicationSettingServiceURL(void)
{
    NSString *URLString = [[NSUserDefaults standardUserDefaults] stringForKey:LetterboxSRGSettingServiceURL];
    return [NSURL URLWithString:URLString] ?: SRGIntegrationLayerProductionServiceURL();
}

BOOL ApplicationSettingIsMirroredOnExternalScreen(void)
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:LetterboxSRGSettingMirroredOnExternalScreen];
}

void ApplicationSettingSetMirroredOnExternalScreen(BOOL mirroredOnExternalScreen)
{
    [[NSUserDefaults standardUserDefaults] setBool:mirroredOnExternalScreen forKey:LetterboxSRGSettingMirroredOnExternalScreen];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [SRGLetterboxService sharedService].mirroredOnExternalScreen = mirroredOnExternalScreen;
}

NSTimeInterval ApplicationSettingStreamAvailabilityCheckInterval(void)
{
    // Set manually to default value, 5 minutes, if no setting.
    NSTimeInterval streamAvailabilityCheckInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:LetterboxSRGSettingStreamAvailabilityCheckInterval];
    return (streamAvailabilityCheckInterval > 0.) ? streamAvailabilityCheckInterval : SRGLetterboxStreamAvailabilityCheckDefaultInterval;
}

@interface ServerSetting : NSObject

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)URL;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL *URL;

@end

@implementation ServerSetting

- (instancetype)initWithName:(NSString *)name URL:(NSURL *)URL
{
    if (self = [super init]) {
        _name = name;
        _URL = URL;
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end

@interface SettingsViewController ()

@property (nonatomic) NSArray<ServerSetting *> *serverSettings;

@end

@implementation SettingsViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    SettingsViewController *viewController = [storyboard instantiateInitialViewController];
    
    viewController.serverSettings = @[[[ServerSetting alloc] initWithName:NSLocalizedString(@"Production", @"Server setting") URL:SRGIntegrationLayerProductionServiceURL()],
                                      [[ServerSetting alloc] initWithName:NSLocalizedString(@"Stage", @"Server setting") URL:SRGIntegrationLayerStagingServiceURL()],
                                      [[ServerSetting alloc] initWithName:NSLocalizedString(@"Test", @"Server setting") URL:SRGIntegrationLayerTestServiceURL()],
                                      [[ServerSetting alloc] initWithName:NSLocalizedString(@"Play MMF", @"Server setting") URL:[NSURL URLWithString:@"https://play-mmf.herokuapp.com"]]];
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"Title of the settings view");
    
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return NSLocalizedString(@"Server", @"Server header title in settings view");
            break;
        }
            
        case 1: {
            return NSLocalizedString(@"Screen mirroring", @"Presentation mode header title in settings view");
            break;
        }
            
        case 2: {
            return NSLocalizedString(@"Stream availability check", @"Stream availability check header title in settings view");
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
    if (section == 2) {
        return NSLocalizedString(@"\nThis demo application presents SRG Letterbox features.\n\nIt is only intended for internal SRG SSR use and should not be distributed outside the company.", @"Warning footer in settings view");
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
        case 2: {
            return 2;
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
                    cell.textLabel.text = NSLocalizedString(@"Disabled", @"Mirrored screens state in settings view");
                    cell.accessoryType = (! ApplicationSettingIsMirroredOnExternalScreen()) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", @"Mirrored screens state in settings view");
                    cell.accessoryType = (ApplicationSettingIsMirroredOnExternalScreen()) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            static NSDateComponentsFormatter *s_dateComponentsFormatter;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
                s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
                s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
                s_dateComponentsFormatter.maximumUnitCount = 1;
            });
            
            switch (indexPath.row) {
                case 0: {
                    NSTimeInterval timeInterval = SRGLetterboxStreamAvailabilityCheckDefaultInterval;
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Default, every %@", @"Default stream availability check interval in settings view"), [s_dateComponentsFormatter stringFromTimeInterval:timeInterval]];
                    cell.accessoryType = (ApplicationSettingStreamAvailabilityCheckInterval() == timeInterval) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    NSTimeInterval timeInterval = LetterboxSRGSettingStreamAvailabilityCheckIntervalShort;
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Short, every %@", @"Default stream availability check interval in settings view"), [s_dateComponentsFormatter stringFromTimeInterval:timeInterval]];
                    cell.accessoryType = (ApplicationSettingStreamAvailabilityCheckInterval() == timeInterval) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            
        default: {
            cell.textLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            NSURL *serverURL = self.serverSettings[indexPath.row].URL;
            [[NSUserDefaults standardUserDefaults] setObject:serverURL.absoluteString forKey:LetterboxSRGSettingServiceURL];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[SRGLetterboxService sharedService].controller reset];
            [SRGLetterboxService sharedService].controller.serviceURL = ApplicationSettingServiceURL();
            break;
        }
            
        case 1: {
            ApplicationSettingSetMirroredOnExternalScreen(indexPath.row == 1);
            break;
        }
            
        case 2: {
            if (indexPath.row == 0) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:LetterboxSRGSettingStreamAvailabilityCheckInterval];
            }
            else {
                [[NSUserDefaults standardUserDefaults] setDouble:LetterboxSRGSettingStreamAvailabilityCheckIntervalShort forKey:LetterboxSRGSettingStreamAvailabilityCheckInterval];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [SRGLetterboxService sharedService].controller.streamAvailabilityCheckInterval = ApplicationSettingStreamAvailabilityCheckInterval();
            break;
        }
            
        default: {
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView reloadData];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
