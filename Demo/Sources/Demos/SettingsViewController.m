//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import "NSBundle+LetterboxDemo.h"

@import SRGAppearance;
@import SRGLetterbox;
@import YYWebImage;

#if TARGET_OS_IOS
@import AppCenterDistribute;
@import SafariServices;
#endif

/**
 *  Setting sections
 */
typedef NS_ENUM(NSInteger, SettingSection) {
    SettingSectionServer = 0,
    SettingSectionUserLocation,
    SettingSectionPlaybackMode,
    SettingSectionAutoplay,
    SettingSectionPreferredQuality,
    SettingSectionUpdateInterval,
#if TARGET_OS_IOS
    SettingSectionScreenMirroring,
    SettingSectionControlCenterIntegration,
    SettingSectionBackgroundVideoPlayback,
#endif
    SettingSectionPrefersMediaContent,
    SettingSectionReset,
#if TARGET_OS_IOS
    SettingSectionApplicationVersion,
#endif
    SettingSectionCount
};

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
NSString * const LetterboxDemoSettingAutoplayEnabled = @"LetterboxDemoSettingAutoplayEnabled";
NSString * const LetterboxDemoSettingQuality = @"LetterboxDemoSettingQuality";
NSString * const LetterboxDemoSettingUserLocation = @"LetterboxDemoSettingUserLocation";
NSString * const LetterboxDemoSettingMirroredOnExternalScreen = @"LetterboxDemoSettingMirroredOnExternalScreen";
NSString * const LetterboxDemoSettingUpdateInterval = @"LetterboxDemoSettingUpdateInterval";
NSString * const LetterboxDemoSettingBackgroundVideoPlaybackEnabled = @"LetterboxDemoSettingBackgroundVideoPlaybackEnabled";
NSString * const LetterboxDemoSettingPrefersMediaContentEnabled = @"LetterboxDemoSettingPrefersMediaContentEnabled";

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

BOOL ApplicationSettingStandalone(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingStandalone];
}

static void ApplicationSettingSetStandalone(BOOL standalone)
{
    [NSUserDefaults.standardUserDefaults setBool:standalone forKey:LetterboxDemoSettingStandalone];
    [NSUserDefaults.standardUserDefaults synchronize];
}

BOOL ApplicationSettingAutoplayEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingAutoplayEnabled];
}

static void ApplicationSettingSetAutoplayEnabled(BOOL enabled)
{
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:LetterboxDemoSettingAutoplayEnabled];
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

BOOL ApplicationSettingPrefersMediaContentEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:LetterboxDemoSettingPrefersMediaContentEnabled];
}

static void ApplicationSettingSetPrefersMediaContentEnabled(BOOL preferredMediaEnabled)
{
    [NSUserDefaults.standardUserDefaults setBool:preferredMediaEnabled forKey:LetterboxDemoSettingPrefersMediaContentEnabled];
    [NSUserDefaults.standardUserDefaults synchronize];
}

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
        self.title = NSLocalizedString(@"Settings", nil);
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Settings", nil);
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if TARGET_OS_TV
    if (@available(tvOS 13, *)) {
        self.navigationController.tabBarObservedScrollView = self.tableView;
    }
#endif
    
    self.tableView.remembersLastFocusedIndexPath = YES;
    [self.tableView reloadData];
}

#pragma mark Cleanup

- (void)clearWebCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    YYImageCache *cache = YYWebImageManager.sharedManager.cache;
    [cache.memoryCache removeAllObjects];
    [cache.diskCache removeAllObjects];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#if TARGET_OS_IOS
    return MSACDistribute.isEnabled ? SettingSectionCount : SettingSectionCount - 1;
#else
    return SettingSectionCount;
#endif
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SettingSectionServer: {
            return NSLocalizedString(@"Server", nil);
            break;
        }
            
        case SettingSectionUserLocation: {
            return NSLocalizedString(@"User location", nil);
            break;
        }
            
        case SettingSectionPlaybackMode: {
            return NSLocalizedString(@"Playback mode", nil);
            break;
        }
            
        case SettingSectionAutoplay: {
            return NSLocalizedString(@"Autoplay", nil);
            break;
        }
            
        case SettingSectionPreferredQuality: {
            return NSLocalizedString(@"Preferred quality", nil);
            break;
        }
        
        case SettingSectionUpdateInterval: {
            return NSLocalizedString(@"Update interval", nil);
            break;
        }
        
#if TARGET_OS_IOS
        case SettingSectionScreenMirroring: {
            return NSLocalizedString(@"Screen mirroring", nil);
            break;
        }
            
        case SettingSectionControlCenterIntegration: {
            return NSLocalizedString(@"Control center integration", nil);
            break;
        }
            
        case SettingSectionBackgroundVideoPlayback: {
            return NSLocalizedString(@"Background video playback", nil);
            break;
        }
            
        case SettingSectionApplicationVersion: {
            return NSLocalizedString(@"Application", nil);
            break;
        }
#endif
            
        case SettingSectionPrefersMediaContent: {
            return NSLocalizedString(@"Prefers media content", nil);
            break;
        }
            
        case SettingSectionReset: {
            return NSLocalizedString(@"Reset", nil);
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
        NSString *versionString = [NSString stringWithFormat:NSLocalizedString(@"Letterbox %@%@", nil), SRGLetterboxMarketingVersion(), [NSBundle.mainBundle.infoDictionary objectForKey:@"BundleNameSuffix"]];
        NSString *buildString = [NSString stringWithFormat:@"%@ %@", [NSBundle.mainBundle.infoDictionary objectForKey:@"BuildName"], [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"]];
        return [NSString stringWithFormat:@"%@ (%@)", versionString, buildString];
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
            
        case SettingSectionAutoplay: {
            return 2;
            break;
        }
        
        case SettingSectionPreferredQuality: {
            return 4;
            break;
        }
            
        case SettingSectionUpdateInterval:
        case SettingSectionPrefersMediaContent: {
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
            
        case SettingSectionReset: {
            return 4;
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
                    cell.textLabel.text = NSLocalizedString(@"Default (IP-based location)", nil);
                    cell.accessoryType = (ApplicationSettingUserLocation() == SettingUserLocationDefault) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Outside Switzerland", nil);
                    cell.accessoryType = (ApplicationSettingUserLocation() == SettingUserLocationOutsideCH) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"Ignore location", nil);
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
                    cell.textLabel.text = NSLocalizedString(@"Default (full-length)", nil);
                    cell.accessoryType = ! ApplicationSettingStandalone() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Standalone", nil);
                    cell.accessoryType = ApplicationSettingStandalone() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            
        case SettingSectionAutoplay: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Disabled", nil);
                    cell.accessoryType = ! ApplicationSettingAutoplayEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", nil);
                    cell.accessoryType = ApplicationSettingAutoplayEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
                    cell.textLabel.text = NSLocalizedString(@"Default", nil);
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualityNone ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Standard definition (SD)", nil);
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualitySD ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"High definition (HD)", nil);
                    cell.accessoryType = ApplicationSettingPreferredQuality() == SRGQualityHD ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 3: {
                    cell.textLabel.text = NSLocalizedString(@"High quality (HQ)", nil);
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
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Default, every %@", nil), [s_dateComponentsFormatter stringFromTimeInterval:timeInterval]];
                    cell.accessoryType = (ApplicationSettingUpdateInterval() == timeInterval) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    NSTimeInterval timeInterval = LetterboxDemoSettingUpdateIntervalShort;
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Short, every %@", nil), [s_dateComponentsFormatter stringFromTimeInterval:timeInterval]];
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
                    cell.textLabel.text = NSLocalizedString(@"Disabled", nil);
                    cell.accessoryType = ! ApplicationSettingIsMirroredOnExternalScreen() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", nil);
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
                    cell.textLabel.text = NSLocalizedString(@"Disabled", nil);
                    cell.accessoryType = ! SRGLetterboxService.sharedService.nowPlayingInfoAndCommandsEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", nil);
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
                    cell.textLabel.text = NSLocalizedString(@"Disabled", nil);
                    cell.accessoryType = ! ApplicationSettingIsBackgroundVideoPlaybackEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", nil);
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
            cell.textLabel.text = NSLocalizedString(@"Versions and release notes", nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
#endif
           
        case SettingSectionPrefersMediaContent: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Disabled (URNs only)", nil);
                    cell.accessoryType = ! ApplicationSettingPrefersMediaContentEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                    
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enabled", nil);
                    cell.accessoryType = ApplicationSettingPrefersMediaContentEnabled() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            
        case SettingSectionReset: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.text = NSLocalizedString(@"Clear web cache", nil);
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
                    
                case 1: {
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.text = NSLocalizedString(@"Clear vector image cache", nil);
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
                    
                case 2: {
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.text = NSLocalizedString(@"Clear all caches", nil);
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
                    
                case 3: {
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.text = NSLocalizedString(@"Simulate memory warning", nil);
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
                    
                default: {
                    cell.textLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
                }
            }
            break;
        };
            
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
            
        case SettingSectionAutoplay: {
            ApplicationSettingSetAutoplayEnabled(indexPath.row == 1);
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
            // Clear internal App Center timestamp to force a new update request
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"MSAppCenterPostponedTimestamp"];
            [MSACDistribute checkForUpdate];
            
            // Display version history
            NSString *appCenterURLString = [NSBundle.mainBundle.infoDictionary objectForKey:@"AppCenterURL"];
            NSURL *appCenterURL = (appCenterURLString.length > 0) ? [NSURL URLWithString:appCenterURLString] : nil;
            if (appCenterURL) {
                SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:appCenterURL];
                [self presentViewController:safariViewController animated:YES completion:nil];
            }
            break;
        }
#endif
            
        case SettingSectionPrefersMediaContent: {
            ApplicationSettingSetPrefersMediaContentEnabled(indexPath.row == 1);
            break;
        }
            
        case SettingSectionReset: {
            switch (indexPath.row) {
                case 0: {
                    [self clearWebCache];
                    break;
                }
                    
                case 1: {
                    [UIImage srg_clearVectorImageCache];
                    break;
                }
                
                case 2: {
                    [self clearWebCache];
                    [UIImage srg_clearVectorImageCache];
                    break;
                }
                    
                case 3: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    NSString *methodName = [[[NSString stringWithFormat:@"_p39e45r2f435o6r7837m12M34e5m6o67r8y8W9a9r66654n43i3n2g"] componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet] componentsJoinedByString:@""];
                    [UIApplication.sharedApplication performSelector:NSSelectorFromString(methodName)];
#pragma clang diagnostic pop
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        default: {
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView reloadData];
}

@end
