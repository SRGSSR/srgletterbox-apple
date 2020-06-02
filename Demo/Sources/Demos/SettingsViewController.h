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

OBJC_EXPORT BOOL ApplicationSettingStandalone(void);
OBJC_EXPORT BOOL ApplicationSettingAutoplayEnabled(void);

OBJC_EXPORT SRGQuality ApplicationSettingPreferredQuality(void);

OBJC_EXPORT API_UNAVAILABLE(tvos) BOOL ApplicationSettingIsMirroredOnExternalScreen(void);
OBJC_EXPORT API_UNAVAILABLE(tvos) void ApplicationSettingSetMirroredOnExternalScreen(BOOL mirroredOnExternalScreen);

OBJC_EXPORT NSTimeInterval ApplicationSettingUpdateInterval(void);

OBJC_EXPORT NSTimeInterval const LetterboxDemoSettingUpdateIntervalShort;

OBJC_EXPORT API_UNAVAILABLE(tvos) BOOL ApplicationSettingIsBackgroundVideoPlaybackEnabled(void);
OBJC_EXPORT BOOL ApplicationSettingPreferredMediaContentEnabled(void);

@interface SettingsViewController : UITableViewController

@end

NS_ASSUME_NONNULL_END
