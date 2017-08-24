//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (SRGLetterbox)

/**
 *  Compatibility method for `-scheduledTimerWithTimeInterval:repeats:block:`, a method only available starting with iOS 10.
 */
// TODO: Remove when iOS 10 is the minimum required version
+ (NSTimer *)srg_scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *))block;

@end

NS_ASSUME_NONNULL_END
