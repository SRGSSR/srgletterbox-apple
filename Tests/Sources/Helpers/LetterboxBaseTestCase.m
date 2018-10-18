//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

NSURL *MMFServiceURL(void)
{
    return [NSURL URLWithString:@"https://play-mmf.herokuapp.com/integrationlayer"];
}

NSString *MMFScheduledOnDemandVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_bipbop_basic_delay_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

NSString *MMFCachedScheduledOnDemandVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_bipbop_basic_cacheddelay_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

NSString *MMFURLChangeVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_mediaplayer_dvr_killswitch_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

NSString *MMFBlockingReasonChangeVideoURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_mediaplayer_dvr_geoblocked_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

NSString *MMFSwissTXTFullDVRURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_rts_info_fulldvr_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

NSString *MMFSwissTXTLimitedDVRURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_rts_info_liveonly_limiteddvr_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

NSString *MMFSwissTXTLiveOnlyURN(NSDate *startDate, NSDate *endDate)
{
    return [NSString stringWithFormat:@"urn:rts:video:_rts_info_liveonly_delay_%@_%@", @((NSInteger)startDate.timeIntervalSince1970), @((NSInteger)endDate.timeIntervalSince1970)];
}

@implementation LetterboxBaseTestCase

#pragma mark Helpers

- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(void (^)(void))handler
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Wait for %@ seconds", @(timeInterval)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
        handler ? handler() : nil;
    });
    return expectation;
}

@end
