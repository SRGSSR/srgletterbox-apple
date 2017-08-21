//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

NSString * const LetterboxSRGSettingServiceURL = @"LetterboxSRGSettingServiceURL";

NSURL * ApplicationSettingServiceURL(void)
{
    NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:LetterboxSRGSettingServiceURL];
    return [NSURL URLWithString:urlString] ?: SRGIntegrationLayerProductionServiceURL();
}

NS_ASSUME_NONNULL_BEGIN

@interface ServerSetting : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL *url;

- (instancetype)initWithName:(NSString *)name url:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

@implementation ServerSetting

- (instancetype)initWithName:(NSString *)name url:(NSURL *)url
{
    if (self = [super init]) {
        _name = name;
        _url = url;
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

@property (nonatomic, weak) IBOutlet UITableViewCell *productionCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *stageCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *testCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *mmfCell;

@property (nonatomic) NSArray<ServerSetting *> *serverSettings;

@end

@implementation SettingsViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    SettingsViewController *viewController = [storyboard instantiateInitialViewController];
    
    viewController.serverSettings = @[[[ServerSetting alloc] initWithName:NSLocalizedString(@"Production", @"server setting") url:SRGIntegrationLayerProductionServiceURL()],
                                      [[ServerSetting alloc] initWithName:NSLocalizedString(@"Stage", @"server setting") url:SRGIntegrationLayerStagingServiceURL()],
                                      [[ServerSetting alloc] initWithName:NSLocalizedString(@"Test", @"server setting") url:SRGIntegrationLayerTestServiceURL()],
                                      [[ServerSetting alloc] initWithName:NSLocalizedString(@"Play MMF", @"server setting") url:[NSURL URLWithString:@"https://play-mmf.herokuapp.com"]]];
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"title of the settings view");
    
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Server", @"server header title in settings view");
            break;
        case 1:
            return NSLocalizedString(@"Mirrored screens", @"Presentation mode header title in settings view");
            break;
            
        default:
            break;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return self.serverSettings.count;
            break;
        case 1:
            return 2;
            break;
            
        default:
            break;
    }
    return 0;
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
            cell.accessoryType = [serverURL isEqual:self.serverSettings[indexPath.row].url] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
            
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Disable", @"Mirrored screens state in settings view");
                    cell.accessoryType = (! [SRGLetterboxService sharedService].mirroredOnExternalScreen) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                };
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Enable", @"Mirrored screens state in settings view");
                    cell.accessoryType = ([SRGLetterboxService sharedService].mirroredOnExternalScreen) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            NSURL *serverURL = self.serverSettings[indexPath.row].url;
            [[NSUserDefaults standardUserDefaults] setObject:serverURL.absoluteString forKey:LetterboxSRGSettingServiceURL];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        }
            
        case 1: {
            [SRGLetterboxService sharedService].mirroredOnExternalScreen = (indexPath.row == 1);
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView reloadData];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
