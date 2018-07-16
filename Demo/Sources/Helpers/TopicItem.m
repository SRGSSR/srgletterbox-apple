//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TopicItem.h"

@interface TopicItem ()

@property (nonatomic) SRGTopic *topic;
@property (nonatomic) NSInteger indentationLevel;

@end

@implementation TopicItem

#pragma mark Object lifecycle

- (instancetype)initWitTopic:(SRGTopic *)topic indentationLevel:(NSInteger)indentationLevel
{
    if (self = [super init]) {
        self.topic = topic;
        self.indentationLevel = indentationLevel;
    }
    return self;
}

@end
