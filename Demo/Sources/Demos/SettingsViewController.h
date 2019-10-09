//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#include "ServerSettings.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSURL *ApplicationSettingServiceURL(void);
OBJC_EXPORT NSDictionary<NSString *, NSString *> *ApplicationSettingGlobalParameters(void);

OBJC_EXPORT BOOL ApplicationSettingIsStandalone(void);

OBJC_EXPORT SRGQuality ApplicationSettingPreferredQuality(void);

OBJC_EXPORT __TVOS_PROHIBITED BOOL ApplicationSettingIsMirroredOnExternalScreen(void);
OBJC_EXPORT __TVOS_PROHIBITED void ApplicationSettingSetMirroredOnExternalScreen(BOOL mirroredOnExternalScreen);

OBJC_EXPORT NSTimeInterval ApplicationSettingUpdateInterval(void);

OBJC_EXPORT NSTimeInterval const LetterboxDemoSettingUpdateIntervalShort;

OBJC_EXPORT __TVOS_PROHIBITED BOOL ApplicationSettingIsBackgroundVideoPlaybackEnabled(void);

__TVOS_PROHIBITED
@interface SettingsViewController : UITableViewController

@end

NS_ASSUME_NONNULL_END
