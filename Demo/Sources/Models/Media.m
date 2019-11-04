//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Media.h"

#import "ServerSettings.h"

#import <SRGDataProvider/SRGDataProvider.h>

@interface Media ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *URN;
@property (nonatomic) NSURL *serviceURL;

@end

@implementation Media

#pragma mark Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];
        if (! self.name) {
            return nil;
        }
        
        self.URN = dictionary[@"urn"];
        
        NSString *service = dictionary[@"service"];
        if (service) {
            static dispatch_once_t s_onceToken;
            static NSDictionary<NSString *, NSURL *> *s_serviceURLs;
            dispatch_once(&s_onceToken, ^{
                s_serviceURLs = @{ @"prod" : SRGIntegrationLayerProductionServiceURL(),
                                   @"stage" : SRGIntegrationLayerStagingServiceURL(),
                                   @"test" : SRGIntegrationLayerTestServiceURL(),
                                   @"mmf" : LetterboxDemoMMFServiceURL() };
            });
            self.serviceURL = s_serviceURLs[service];
        }
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)URN
{
    NSString *URN = _URN;
    if ([URN containsString:@"_100DAYS_"]) {
        NSString *originalURN = [URN stringByReplacingOccurrencesOfString:@"_100DAYS_" withString:@""];
        
        NSDate *nowDate = NSDate.date;
        
        NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
        startDateComponents.day = 100;
        startDateComponents.second = 7;
        NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
        endDateComponents.day = 101;
        NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        return [NSString stringWithFormat:@"%@_%@_%@", originalURN, @(startTimestamp), @(endTimestamp)];
    }
    else if ([URN containsString:@"_1DAY_"]) {
        NSString *originalURN = [URN stringByReplacingOccurrencesOfString:@"_1DAY_" withString:@""];
        
        NSDate *nowDate = NSDate.date;
        
        NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
        startDateComponents.day = 1;
        startDateComponents.second = 7;
        NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
        endDateComponents.day = 2;
        NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        return [NSString stringWithFormat:@"%@_%@_%@", originalURN, @(startTimestamp), @(endTimestamp)];
    }
    else if ([URN containsString:@"_1HOUR_"]) {
        NSString *originalURN = [URN stringByReplacingOccurrencesOfString:@"_1HOUR_" withString:@""];
        
        NSDate *nowDate = NSDate.date;
        
        NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
        startDateComponents.hour = 1;
        startDateComponents.second = 7;
        NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
        endDateComponents.hour = 2;
        NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        return [NSString stringWithFormat:@"%@_%@_%@", originalURN, @(startTimestamp), @(endTimestamp)];
    }
    else if ([URN containsString:@"_START_"]) {
        NSString *originalURN = [URN stringByReplacingOccurrencesOfString:@"_START_" withString:@""];
        
        NSDate *nowDate = NSDate.date;
        
        NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
        startDateComponents.second = 7;
        NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
        endDateComponents.hour = 2;
        NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        return [NSString stringWithFormat:@"%@_%@_%@", originalURN, @(startTimestamp), @(endTimestamp)];
    }
    else if ([URN containsString:@"_SOON_EXPIRED_"]) {
        NSString *originalURN = [URN stringByReplacingOccurrencesOfString:@"_SOON_EXPIRED_" withString:@""];
        
        NSDate *nowDate = NSDate.date;
        
        NSDateComponents *startDateComponents = [[NSDateComponents alloc] init];
        startDateComponents.second = -100;
        NSInteger startTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:startDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        NSDateComponents *endDateComponents = [[NSDateComponents alloc] init];
        endDateComponents.second = 10;
        NSInteger endTimestamp = [[NSCalendar currentCalendar] dateByAddingComponents:endDateComponents toDate:nowDate options:0].timeIntervalSince1970;
        
        return [NSString stringWithFormat:@"%@_%@_%@", originalURN, @(startTimestamp), @(endTimestamp)];
    }
    else {
        return URN;
    }
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; name = %@; URN = %@>",
            [self class],
            self,
            self.name,
            self.URN];
}

@end
