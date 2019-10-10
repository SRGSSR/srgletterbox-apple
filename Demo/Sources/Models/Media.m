//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Media.h"

@interface Media ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *URN;
@property (nonatomic, getter=forBasic) BOOL basic;
@property (nonatomic, getter=forPageNagivation) BOOL pageNagivation;
@property (nonatomic, getter=isOnMMF) BOOL onMMF;

@end

@implementation Media

+ (NSArray<Media *> *)mediasFromFileAtPath:(NSString *)filePath
{
    NSArray<NSDictionary *> *mediaDictionaries = [NSDictionary dictionaryWithContentsOfFile:filePath][@"medias"];
    
    NSMutableArray<Media *> *medias = [NSMutableArray array];
    for (NSDictionary *mediaDictionary in mediaDictionaries) {
        Media *media = [[self alloc] initWithDictionary:mediaDictionary];
        if (media) {
            [medias addObject:media];
        }
    }
    return [medias copy];
}

#pragma mark Object lifecycle

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];
        if (! self.name) {
            return nil;
        }
        
        self.URN = dictionary[@"urn"];
        self.basic = [dictionary[@"basic"] boolValue];
        self.pageNagivation = [dictionary[@"pageNagivation"] boolValue];
        self.onMMF = [dictionary[@"onMMF"] boolValue];
    }
    return self;
}

#pragma mark Getters
- (NSString *)URN
{
    NSString *tmpURN = _URN;
    if ([tmpURN containsString:@"_ADD100DAYS_"]) {
        NSString *originalURN = [tmpURN stringByReplacingOccurrencesOfString:@"_ADD100DAYS_" withString:@""];
        
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
    if ([tmpURN containsString:@"_ADD1DAY_"]) {
        NSString *originalURN = [tmpURN stringByReplacingOccurrencesOfString:@"_ADD1DAY_" withString:@""];
        
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
    if ([tmpURN containsString:@"_ADD1HOUR_"]) {
        NSString *originalURN = [tmpURN stringByReplacingOccurrencesOfString:@"_ADD1HOUR_" withString:@""];
        
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
    else {
        return tmpURN;
    }
}

@end
