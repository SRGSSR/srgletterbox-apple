//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSURL *ApplicationSettingServiceURL(void);

OBJC_EXPORT BOOL ApplicationSettingIsMirroredOnExternalScreen(void);
OBJC_EXPORT void ApplicationSettingSetMirroredOnExternalScreen(BOOL mirroredOnExternalScreen);

@interface SettingsViewController : UITableViewController

@end

NS_ASSUME_NONNULL_END
