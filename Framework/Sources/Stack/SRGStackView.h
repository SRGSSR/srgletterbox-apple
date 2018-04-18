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

// TODO: Find declarative formalism for convenient construction (also in nested hierarchies)

IB_DESIGNABLE
@interface SRGStackView : UIView

// TODO: If a view has no height in the final layout, no spacing should probably be added. Might be tricky to implement
//       since ultimately depends on the final layout. Might not be a good idea. Check UIStackView behavior.
@property (nonatomic) CGFloat spacing;

// TODO: Check if change is correctly animated
@property (nonatomic) SRGStackViewDirection direction;

// TODO: Attributes must be updatable at runtime -> probably rename the block and call it with each layout pass.
- (void)addSubview:(UIView *)view withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;
- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;
- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview withAttributes:(void (^)(SRGStackAttributes *attributes))attributes;

@end

NS_ASSUME_NONNULL_END
