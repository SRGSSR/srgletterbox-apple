//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSURL *LetterboxDemoMMFServiceURL(void);

OBJC_EXPORT NSURL *ApplicationSettingServiceURL(void);
OBJC_EXPORT NSDictionary<NSString *, NSString *> *ApplicationSettingGlobalParameters(void);

OBJC_EXPORT BOOL ApplicationSettingIsStandalone(void);

OBJC_EXPORT BOOL ApplicationSettingIsMirroredOnExternalScreen(void);
OBJC_EXPORT void ApplicationSettingSetMirroredOnExternalScreen(BOOL mirroredOnExternalScreen);

OBJC_EXPORT NSTimeInterval ApplicationSettingUpdateInterval(void);

OBJC_EXPORT NSTimeInterval const LetterboxDemoSettingUpdateIntervalShort;

@interface SettingsViewController : UITableViewController

@end

NS_ASSUME_NONNULL_END
