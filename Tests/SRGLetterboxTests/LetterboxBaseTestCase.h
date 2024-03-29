//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import XCTest;

NS_ASSUME_NONNULL_BEGIN

static NSString * const OnDemandVideoURN = @"urn:swi:video:42844052";
static NSString * const OnDemandVideoTokenURN = @"urn:rts:video:1967124";
static NSString * const OnDemand360VideoURN = @"urn:rts:video:8414077";
static NSString * const OnDemandLongVideoURN = @"urn:srf:video:2c685129-bad8-4ea0-93f5-0d6cff8cb156";
static NSString * const OnDemandLongVideoSegmentURN = @"urn:srf:video:5fe1618a-b710-42aa-ac8a-cb9eabf42426";
static NSString * const OnDemandAudioWithChaptersURN = @"urn:rts:audio:9355007";
static NSString * const LiveVideoURN = @"urn:rts:video:8841634";
static NSString * const LiveVideo2URN = @"urn:rts:video:1967124";
static NSString * const LiveAudioURN = @"urn:srf:audio:69e8ac16-4327-4af4-b873-fd5cd6e895a7";
static NSString * const OnDemandVideoWithLegalBlockedContentURN = @"urn:srf:video:40ca0277-0e53-4312-83e2-4710354ff53e";
static NSString * const OnDemandVideoWithLegalBlockedContentSegementURN = @"urn:srf:video:84135f7b-c58d-4a2d-b0b0-e8680581eede";

static NSString * const MMFLiveDVRVideoURN = @"urn:rts:video:_couleur3";
static NSString * const MMFNonProtectedMediaChangedURN = @"urn:rts:video:_mediacompositionChangedURN";
static NSString * const MMFProtectedMediaChangedURN = @"urn:rts:video:_mediacompositionProtectedStreamChangedURN";

static NSString * const OnDemandLongVideo2URN = @"urn:rts:video:8992584";
static NSString * const OnDemandLongVideo2GeoblockedSegmentURN = @"urn:rts:video:8992624";

OBJC_EXPORT NSURL *MMFServiceURL(void);
OBJC_EXPORT NSString *MMFScheduledOnDemandVideoURN(NSDate *startDate, NSDate *endDate);
OBJC_EXPORT NSString *MMFCachedScheduledOnDemandVideoURN(NSDate *startDate, NSDate *endDate);
OBJC_EXPORT NSString *MMFURLChangeVideoURN(NSDate *startDate, NSDate *endDate);
OBJC_EXPORT NSString *MMFBlockingReasonChangeVideoURN(NSDate *startDate, NSDate *endDate);
OBJC_EXPORT NSString *MMFSwissTXTFullDVRURN(NSDate *startDate, NSDate *endDate);
OBJC_EXPORT NSString *MMFSwissTXTLimitedDVRURN(NSDate *startDate, NSDate *endDate);
OBJC_EXPORT NSString *MMFSwissTXTLiveOnlyURN(NSDate *startDate, NSDate *endDate);

OBJC_EXPORT NSURL *MMFServiceURL(void);

@interface LetterboxBaseTestCase : XCTestCase

/**
 *  Replacement for the buggy `-expectationForNotification:object:handler:`, catching notifications only once.
 *  See http://openradar.appspot.com/radar?id=4976563959365632.
 */
- (XCTestExpectation *)expectationForSingleNotification:(NSNotificationName)notificationName object:(nullable id)objectToObserve handler:(nullable XCNotificationExpectationHandler)handler;

/**
 *  Expectation fulfilled after some given time interval (in seconds), calling the optionally provided handler. Can
 *  be useful for ensuring nothing unexpected occurs during some time
 */
- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(nullable void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
