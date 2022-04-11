//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

@import libextobjc;
@import SRGLetterbox;

@interface RateTestCase : LetterboxBaseTestCase

@property (nonatomic) SRGLetterboxController *controller;

@end

@implementation RateTestCase

#pragma mark Setup and tear down

- (void)setUp
{
    self.controller = [[SRGLetterboxController alloc] init];
}

- (void)tearDown
{
    // Always ensure the player gets deallocated between tests
    [self.controller reset];
    self.controller = nil;
}

#pragma mark Tests

- (void)testPlaybackRateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, playbackRate) expectedValue:@2];
    
    self.controller.playbackRate = 2.f;
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, playbackRate) expectedValue:@0.5];
    
    self.controller.playbackRate = 0.5f;
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

- (void)testEffectivePlaybackRateKeyValueObserving
{
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, effectivePlaybackRate) expectedValue:@2];
    
    self.controller.playbackRate = 2.f;
    [self.controller playURN:OnDemandVideoURN atPosition:nil withPreferredSettings:nil];
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
    
    [self keyValueObservingExpectationForObject:self.controller keyPath:@keypath(SRGLetterboxController.new, effectivePlaybackRate) expectedValue:@0.5];
    
    self.controller.playbackRate = 0.5f;
    
    [self waitForExpectationsWithTimeout:10. handler:nil];
}

@end
