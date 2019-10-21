//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import <AppCenterDistribute/AppCenterDistribute.h>
#import <SafariServices/SafariServices.h>
#import <SRGLetterbox/SRGLetterbox.h>

/**
 *  User location options.
 */
typedef NS_ENUM(NSInteger, SettingUserLocation) {
    /**
     *  Default IP-based location.
     */
    SettingUserLocationDefault,
    /**
     *  Outside Switzerland.
     */
    SettingUserLocationOutsideCH,
    /**
     *  Ignore location.
     */
    SettingUserLocationIgnored
};

NSValueTransformer *SettingUserLocationTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"WW" : @(SettingUserLocationOutsideCH),
                                                                                         @"CH" : @(SettingUserLocationIgnored) }
                                                                         defaultValue:@(SettingUserLocationDefault)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

NSString * const LetterboxDemoSettingServiceURL = @"LetterboxDemoSettingServiceURL";
NSString * const LetterboxDemoSettingStandalone = @"LetterboxDemoSettingStandalone";
NSString * const LetterboxDemoSettingQuality = @"LetterboxDemoSettingQuality";
NSString * const LetterboxDemoSettingUserLocation = @"LetterboxDemoSettingUserLocation";
NSString * const LetterboxDemoSettingMirroredOnExternalScreen = @"LetterboxDemoSettingMirroredOnExternalScreen";
NSString * const LetterboxDemoSettingUpdateInterval = @"LetterboxDemoSettingUpdateInterval";
NSString * const LetterboxDemoSettingBackgroundVideoPlaybackEnabled = @"LetterboxDemoSettingBackgroundVideoPlaybackEnabled";

NSTimeInterval const LetterboxDemoSettingUpdateIntervalShort = 10.;

static void SettingServiceURLReset(void)
{
    BOOL settingServiceURLReset = [NSUserDefaults.standardUserDefaults boolForKey:@"SettingServiceURLReset2"];
    if (! settingServiceURLReset) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:LetterboxDemoSettingServiceURL];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:LetterboxDemoSettingUserLocation];
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"SettingServiceURLReset2"];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

NSURL *ApplicationSettingServiceURL(void)
{
    SettingServiceURLReset();
    NSString *URLString = [NSUserDefaults.standardUserDefaults stringForKey:LetterboxDemoSettingServiceURL];
    return [NSURL URLWithString:URLString] ?: SRGIntegrationLayerProductionServiceURL();
}

static SettingUserLocation ApplicationSettingUserLocation(void)
{
    return [[SettingUserLocationTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:LetterboxDemoSettingUserLocation]] integerValue];
}

static void ApplicationSettingSetUserLocation(SettingUserLocation settingUserLocation)
{
    [NSUserDefaults.standardUserDefaults setObject:[SettingUserLocationTransformer() reverseTransformedValue:@(settingUserLocation)] forKey:LetterboxDemoSettingUserLocation];
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

SRGQuality ApplicationSettingPreferredQuality(void)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSNumber *> *s_strings_qualities;
    dispatch_once(&s_onceToken, ^{
        s_strings_qualities = @{ @"SD" : @(SRGQualitySD),
                                 @"HD" : @(SRGQualityHD),
                                 @"HQ" : @(SRGQualityHQ) };
    });
    
    NSString *qualityString = [NSUserDefaults.standardUserDefaults stringForKey:LetterboxDemoSettingQuality];
    NSNumber *qualityNumber = s_strings_qualities[qualityString] ?: @(SRGQualityNone);
    return qualityNumber.integerValue;
}

static void ApplicationSettingSetPreferredQuality(SRGQuality quality)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_qualities_strings;
    dispatch_once(&s_onceToken, ^{
        s_qualities_strings = @{ @(SRGQualitySD) : @"SD",
                                 @(SRGQualityHD) : @"HD",
                                 @(SRGQualityHQ) : @"HQ" };
    });
    
    NSString *qualityString = s_qualities_strings[@(quality)];
    [NSUserDefaults.standardUserDefaults setObject:qualityString forKey:LetterboxDemoSettingQuality];
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

BOOL ApplicationSettingIsBackgroundVideoPlaybackEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingBackgroundVideoPlaybackEnabled];
}

static void ApplicationSettingSetBackgroundVideoPlaybackEnabled(BOOL backgroundVideoPlaybackEnabled)
{
    [NSUserDefaults.standardUserDefaults setBool:backgroundVideoPlaybackEnabled forKey:LetterboxDemoSettingBackgroundVideoPlaybackEnabled];
    [NSUserDefaults.standardUserDefaults synchronize];
}

NSDictionary<NSString *, NSString *> *ApplicationSettingGlobalParameters(void)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_locations;
    dispatch_once(&s_onceToken, ^{
        s_locations = @{ @(SettingUserLocationOutsideCH) : @"WW",
                         @(SettingUserLocationIgnored) : @"CH" };
    });
    
    NSString *location = s_locations[@(ApplicationSettingUserLocation())];
    return location ? @{ @"forceLocation" : location } : nil;
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
    viewController.serverSettings = ServerSettings.serverSettings;
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
    return MSDistribute.isEnabled ? 9 : 8;
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
            return NSLocalizedString(@"Preferred quality", @"Preferred quality mode header title in settings view");
            break;
        }
            
        case 4: {
            return NSLocalizedString(@"Screen mirroring", @"Presentation mode header title in settings view");
            break;
        }
            
        case 5: {
            return NSLocalizedString(@"Control center integration", @"Control center integration title in settings view");
            break;
        }
            
        case 6: {
            return NSLocalizedString(@"Update interval", @"Update interval header title in settings view");
            break;
        }
            
        case 7: {
            return NSLocalizedString(@"Background video playback", @"Background video playback header title in settings view");
            break;
        }
            
        case 8: {
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
        return [NSString stringWithFormat:NSLocalizedString(@"This demo application presents SRG Letterbox features (version %@).", @"Information footer in settings view"),
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
            
        case 1: {
            return 3;
            break;
        }
            
        case 2: {
            return 2;
            break;
        }
        
        case 3: {
            return 4;
            break;
        }
        
        case 4:
        case 5:
        case 6:
        case 7: {
            return 2;
            break;
        }
            
        case 8: {
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
                    cell.textLabel.text = NSLocalizedString(@"Default (IP-based location)", @"Label for the defaut location setting");
                    cell.accessoryType = (ApplicationSettingUserLocation() == SettingUserLocationDefault) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Outside Switzerland", @"Label for the outside Switzerland location setting");
                    cell.accessoryType = (ApplicationSettingUserLocation() == SettingUserLocationOutsideCH) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"Ignore location", @"Label for the ignored location setting");
                    cell.accessoryType = (ApplicationSettingUserLocation() == SettingUserLocationIgnored) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
                    cell.textLabel.text = NSLocalizedString(@"Default", @"Label for the defaut quality setting");
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualityNone ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Standard definition (SD)", @"Label for the SD quality setting");
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualitySD ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"High definition (HD)", @"Label for the HD quality setting");
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualityHD ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 3: {
                    cell.textLabel.text = NSLocalizedString(@"High quality (HQ)", @"Label for the HQ quality setting");
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualityHQ ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            
        case 5: {
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
            
        case 6: {
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
            
        case 7: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Disabled", @"Label for a disabled setting");
                    cell.accessoryType = ! ApplicationSettingIsBackgroundVideoPlaybackEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", @"Label for an enabled setting");
                    cell.accessoryType = ApplicationSettingIsBackgroundVideoPlaybackEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            
        case 8: {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Check for updates", @"Check for updates button in settings view");
            cell.accessoryType = UITableViewCellAccessoryNone;
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
            ApplicationSettingSetUserLocation(indexPath.row);
            
            [SRGLetterboxService.sharedService.controller reset];
            SRGLetterboxService.sharedService.controller.globalParameters = ApplicationSettingGlobalParameters();
            break;
        }
            
        case 2: {
            ApplicationSettingSetStandalone(indexPath.row == 1);
            break;
        }
            
        case 3: {
            ApplicationSettingSetPreferredQuality(indexPath.row);
            break;
        }
            
        case 4: {
            ApplicationSettingSetMirroredOnExternalScreen(indexPath.row == 1);
            break;
        }
            
        case 5: {
            SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled = (indexPath.row == 1);
            break;
        }
            
        case 6: {
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
            
        case 7: {
            ApplicationSettingSetBackgroundVideoPlaybackEnabled(indexPath.row == 1);
            SRGLetterboxService.sharedService.controller.backgroundVideoPlaybackEnabled = (indexPath.row == 1);
            break;
        }
            
        case 8: {
            completionBlock = ^{
                UIViewController *viewController = UIApplication.sharedApplication.delegate.window.rootViewController;
                NSString *appCenterURLString = [NSBundle.mainBundle.infoDictionary objectForKey:@"AppCenterURL"];
                NSURL *defaultURL = (appCenterURLString.length > 0) ? [NSURL URLWithString:appCenterURLString] : nil;
                
                NSString *message = (defaultURL) ? [NSString stringWithFormat:NSLocalizedString(@"The current version is %@.", @"Check for updates alert message"), [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"]] : NSLocalizedString(@"No information.", @"Check for updates alert message with no update url.");
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Check for updates", @"Check for updates alert title")
                                                                                         message:message
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
                if (defaultURL) {
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open release notes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:defaultURL];
                        [viewController presentViewController:safariViewController animated:YES completion:nil];
                    }]];
                }
                [viewController presentViewController:alertController animated:YES completion:nil];
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
