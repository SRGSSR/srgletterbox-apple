//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemosViewController : UITableViewController

- (void)openModalPlayerWithURN:(NSString *)URN serviceURL:(nullable NSURL *)serviceURL updateInterval:(nullable NSNumber *)updateInterval;

@end

NS_ASSUME_NONNULL_END
