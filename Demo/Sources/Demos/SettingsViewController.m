//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import "NSBundle+LetterboxDemo.h"

#import <AppCenterDistribute/AppCenterDistribute.h>
#import <SafariServices/SafariServices.h>
#import <SRGLetterbox/SRGLetterbox.h>

#if TARGET_OS_IOS
#import <HockeySDK/HockeySDK.h>
#endif

/**
 *  Setting sections
 */
typedef NS_ENUM(NSInteger, SettingSection) {
    SettingSectionServer = 0,
    SettingSectionUserLocation,
    SettingSectionPlaybackMode,
    SettingSectionPreferredQuality,
    SettingSectionUpdateInterval,
#if TARGET_OS_IOS
    SettingSectionScreenMirroring,
    SettingSectionControlCenterIntegration,
    SettingSectionBackgroundVideoPlayback,
    SettingSectionApplicationVersion,
#endif
    SettingSectionMax
};

NSUInteger const SettingSectionCount = SettingSectionMax;

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

#if TARGET_OS_IOS
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

BOOL ApplicationSettingIsBackgroundVideoPlaybackEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingBackgroundVideoPlaybackEnabled];
}

static void ApplicationSettingSetBackgroundVideoPlaybackEnabled(BOOL backgroundVideoPlaybackEnabled)
{
    [NSUserDefaults.standardUserDefaults setBool:backgroundVideoPlaybackEnabled forKey:LetterboxDemoSettingBackgroundVideoPlaybackEnabled];
    [NSUserDefaults.standardUserDefaults synchronize];
}
#endif

NSTimeInterval ApplicationSettingUpdateInterval(void)
{
    // Set manually to default value, 5 minutes, if no setting.
    NSTimeInterval updateInterval = [NSUserDefaults.standardUserDefaults doubleForKey:LetterboxDemoSettingUpdateInterval];
    return (updateInterval > 0.) ? updateInterval : SRGLetterboxDefaultUpdateInterval;
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

/**
 *  Private App Center implementation details.
 */
@interface MSDistribute (Private)

+ (id)sharedInstance;
- (void)startUpdate;

@end

@interface SettingsViewController ()

@property (nonatomic) NSArray<ServerSettings *> *serverSettings;

@end

@implementation SettingsViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.serverSettings = ServerSettings.serverSettings;
        self.title = NSLocalizedString(@"Settings", @"Settings view title");
    }
    return self;
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
#if TARGET_OS_IOS
    return MSDistribute.isEnabled ? 9 : 8;
#else
    return SettingSectionCount;
#endif
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SettingSectionServer: {
            return NSLocalizedString(@"Server", @"Server header title in settings view");
            break;
        }
            
        case SettingSectionUserLocation: {
            return NSLocalizedString(@"User location", @"User location header title in settings view");
            break;
        }
            
        case SettingSectionPlaybackMode: {
            return NSLocalizedString(@"Playback mode", @"Playback mode header title in settings view");
            break;
        }
            
        case SettingSectionPreferredQuality: {
            return NSLocalizedString(@"Preferred quality", @"Preferred quality mode header title in settings view");
            break;
        }
        
        case SettingSectionUpdateInterval: {
            return NSLocalizedString(@"Update interval", @"Update interval header title in settings view");
            break;
        }
        
#if TARGET_OS_IOS
        case SettingSectionScreenMirroring: {
            return NSLocalizedString(@"Screen mirroring", @"Presentation mode header title in settings view");
            break;
        }
            
        case SettingSectionControlCenterIntegration: {
            return NSLocalizedString(@"Control center integration", @"Control center integration title in settings view");
            break;
        }
            
        case SettingSectionBackgroundVideoPlayback: {
            return NSLocalizedString(@"Background video playback", @"Background video playback header title in settings view");
            break;
        }
            
        case SettingSectionApplicationVersion: {
            NSString *buildNumberString = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"];
            return [NSString stringWithFormat:@"%@ (build %@)", NSLocalizedString(@"Application", @"Application header title in settings view"), buildNumberString];
            break;
        }
#endif
            
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
        case SettingSectionServer: {
            return self.serverSettings.count;
            break;
        }
            
        case SettingSectionUserLocation: {
            return 3;
            break;
        }
            
        case SettingSectionPlaybackMode: {
            return 2;
            break;
        }
        
        case SettingSectionPreferredQuality: {
            return 4;
            break;
        }
            
        case SettingSectionUpdateInterval: {
            return 2;
            break;
        }
        
#if TARGET_OS_IOS
        case SettingSectionScreenMirroring:
        case SettingSectionControlCenterIntegration:
        case SettingSectionBackgroundVideoPlayback: {
            return 2;
            break;
        }
            
        case SettingSectionApplicationVersion: {
            return 1;
            break;
        }
#endif
            
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"SettingsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    
    switch (indexPath.section) {
        case SettingSectionServer: {
            cell.textLabel.text = self.serverSettings[indexPath.row].name;
            
            NSURL *serverURL = ApplicationSettingServiceURL();
            cell.accessoryType = [serverURL isEqual:self.serverSettings[indexPath.row].URL] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
            
        case SettingSectionUserLocation: {
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
            
        case SettingSectionPlaybackMode: {
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
            
        case SettingSectionPreferredQuality: {
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
            
        case SettingSectionUpdateInterval: {
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

#if TARGET_OS_IOS
        case SettingSectionScreenMirroring: {
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
            
        case SettingSectionControlCenterIntegration: {
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
            
        case SettingSectionBackgroundVideoPlayback: {
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
            
        case SettingSectionApplicationVersion: {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Check for updates", @"Check for updates button in settings view");
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
#endif
            
        default: {
            cell.textLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if TARGET_OS_IOS
    void (^completionBlock)(void) = nil;
#endif
    
    switch (indexPath.section) {
        case SettingSectionServer: {
            ServerSettings *serverSettings = self.serverSettings[indexPath.row];
            [NSUserDefaults.standardUserDefaults setObject:serverSettings.URL.absoluteString forKey:LetterboxDemoSettingServiceURL];
            [NSUserDefaults.standardUserDefaults synchronize];
            
#if TARGET_OS_IOS
            [SRGLetterboxService.sharedService.controller reset];
            SRGLetterboxService.sharedService.controller.serviceURL = ApplicationSettingServiceURL();
#endif
            break;
        }
            
        case SettingSectionUserLocation: {
            ApplicationSettingSetUserLocation(indexPath.row);
            
#if TARGET_OS_IOS
            [SRGLetterboxService.sharedService.controller reset];
            SRGLetterboxService.sharedService.controller.globalParameters = ApplicationSettingGlobalParameters();
#endif
            break;
        }
            
        case SettingSectionPlaybackMode: {
            ApplicationSettingSetStandalone(indexPath.row == 1);
            break;
        }
            
        case SettingSectionPreferredQuality: {
            ApplicationSettingSetPreferredQuality(indexPath.row);
            break;
        }
            
        case SettingSectionUpdateInterval: {
            if (indexPath.row == 0) {
                [NSUserDefaults.standardUserDefaults removeObjectForKey:LetterboxDemoSettingUpdateInterval];
            }
            else {
                [NSUserDefaults.standardUserDefaults setDouble:LetterboxDemoSettingUpdateIntervalShort forKey:LetterboxDemoSettingUpdateInterval];
            }
            [NSUserDefaults.standardUserDefaults synchronize];
            
#if TARGET_OS_IOS
            SRGLetterboxService.sharedService.controller.updateInterval = ApplicationSettingUpdateInterval();
#endif
            break;
        }
            
#if TARGET_OS_IOS
        case SettingSectionScreenMirroring: {
            ApplicationSettingSetMirroredOnExternalScreen(indexPath.row == 1);
            break;
        }
            
        case SettingSectionControlCenterIntegration: {
            SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled = (indexPath.row == 1);
            break;
        }
            
        case SettingSectionBackgroundVideoPlayback: {
            ApplicationSettingSetBackgroundVideoPlaybackEnabled(indexPath.row == 1);
            SRGLetterboxService.sharedService.controller.backgroundVideoPlaybackEnabled = (indexPath.row == 1);
            break;
        }
            
        case SettingSectionApplicationVersion: {
            completionBlock = ^{
                // Clear internal App Center timestamp to force a new update request
                [NSUserDefaults.standardUserDefaults removeObjectForKey:@"MSPostponedTimestamp"];
                [[MSDistribute sharedInstance] startUpdate];
                
                // Display version history
                NSString *appCenterURLString = [NSBundle.mainBundle.infoDictionary objectForKey:@"AppCenterURL"];
                NSURL *appCenterURL = (appCenterURLString.length > 0) ? [NSURL URLWithString:appCenterURLString] : nil;
                if (appCenterURL) {
                    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:appCenterURL];
                    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
                    [rootViewController presentViewController:safariViewController animated:YES completion:nil];
                }
            };
            break;
        }
#endif
            
        default: {
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView reloadData];
    
#if TARGET_OS_IOS
    [self.presentingViewController dismissViewControllerAnimated:YES completion:completionBlock];
#endif
}

@end
