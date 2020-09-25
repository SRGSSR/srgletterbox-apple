//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface TopicItem : NSObject

- (instancetype)initWitTopic:(SRGTopic *)topic indentationLevel:(NSInteger)indentationLevel;

@property (nonatomic, readonly) SRGTopic *topic;
@property (nonatomic, readonly) NSInteger indentationLevel;

@end

NS_ASSUME_NONNULL_END
