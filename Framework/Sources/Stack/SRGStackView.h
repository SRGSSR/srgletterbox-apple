//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SRGStackViewDirection) {
    SRGStackViewDirectionVertical,
    SRGStackViewDirectionHorizontal
};

@interface SRGStackAttributes : NSObject

@property (nonatomic) CGFloat length;
@property (nonatomic) NSUInteger hugging;
@property (nonatomic) NSUInteger resistance;

@end

IB_DESIGNABLE
@interface SRGStackView : UIView

@property (nonatomic) CGFloat spacing;
@property (nonatomic) SRGStackViewDirection direction;

- (void)addSubview:(UIView *)view withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;
- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;
- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;

@end

NS_ASSUME_NONNULL_END
