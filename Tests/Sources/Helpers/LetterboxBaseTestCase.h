//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface LetterboxBaseTestCase : XCTestCase

/**
 *  Return `YES` iff content protection is available. Without it, some streams cannot be played (e.g. livestreams)
 *  and therefore some tests cannot work.
 */
+ (BOOL)hasContentProtection;

/**
 *  Expectation fulfilled after some given time interval (in seconds), calling the optionally provided handler. Can
 *  be useful for ensuring nothing unexpected occurs during some time
 */
- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(nullable void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
