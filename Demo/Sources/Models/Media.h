//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Media : NSObject

+ (NSArray<Media *> *)mediasFromFileAtPath:(NSString *)filePath;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *URN;
@property (nonatomic, readonly, getter=forBasic) BOOL basic;
@property (nonatomic, readonly, getter=forPageNagivation) BOOL pageNagivation;
@property (nonatomic, readonly, getter=isOnMMF) BOOL onMMF;

@end

NS_ASSUME_NONNULL_END
