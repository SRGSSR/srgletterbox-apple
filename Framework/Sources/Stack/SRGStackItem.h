//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGStackView.h"

@interface SRGStackItem : NSObject

+ (NSArray<SRGStackItem *> *)stackItemsForViews:(NSArray<UIView *> *)views withDirection:(SRGStackViewDirection)direction orthogonalLength:(CGFloat)orthogonalLength;

@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) CGFloat length;
@property (nonatomic, readonly) NSUInteger hugging;
@property (nonatomic, readonly) NSUInteger resistance;

@end
