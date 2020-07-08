//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoSection.h"

@interface DemoSection ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic,) NSArray<Media *> *medias;

@end

@implementation DemoSection

#pragma mark Class methods

+ (NSArray<DemoSection *> *)sections
{
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"MediaDemoConfiguration" ofType:@"plist"];
    NSArray<NSDictionary *> *sectionDictionaries = [NSDictionary dictionaryWithContentsOfFile:filePath][@"sections"];
    
    NSMutableArray<DemoSection *> *sections = [NSMutableArray array];
    for (NSDictionary *sectionDictionary in sectionDictionaries) {
        DemoSection *section = [[self alloc] initWithDictionary:sectionDictionary];
        if (section) {
            [sections addObject:section];
        }
    }
    return sections.copy;
}

#pragma mark Object lifecycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];        
        self.summary = dictionary[@"summary"];
        
        NSMutableArray<Media *> *medias = [NSMutableArray array];
        for (NSDictionary *mediaDictionary in dictionary[@"medias"]) {
            Media *media = [[Media alloc] initWithDictionary:mediaDictionary];
            if (media) {
                [medias addObject:media];
            }
        }
        self.medias = medias.copy;
    }
    return self;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; name = %@; medias = %@>",
            self.class,
            self,
            self.name,
            self.medias];
}

@end
