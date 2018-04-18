//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGStackItem.h"

#import "UIView+SRGStackView.h"

@interface SRGStackItem ()

@property (nonatomic) UIView *view;
@property (nonatomic) CGFloat length;
@property (nonatomic) NSUInteger hugging;
@property (nonatomic) NSUInteger resistance;

@end

@implementation SRGStackItem

+ (NSArray<SRGStackItem *> *)stackItemsForViews:(NSArray<UIView *> *)views withDirection:(SRGStackViewDirection)direction orthogonalLength:(CGFloat)orthogonalLength
{
    NSMutableArray *stackItems = [NSMutableArray array];
    for (UIView *subview in views) {
        if (subview.hidden) {
            continue;
        }
        
        SRGStackItem *stackItem = [[SRGStackItem alloc] initWithView:subview direction:direction orthogonalLength:orthogonalLength];
        [stackItems addObject:stackItem];
    }
    return [stackItems copy];
}

- (instancetype)initWithView:(UIView *)view direction:(SRGStackViewDirection)direction orthogonalLength:(CGFloat)orthogonalLength
{
    if (self = [super init]) {
        CGFloat length = 0.f;
        
        SRGStackView *stackView = [view isKindOfClass:[SRGStackView class]] ? (SRGStackView *)view : nil;
        SRGStackAttributes *attributes = view.srg_stackAttributes;
        if (attributes.length >= 0.f) {
            length = attributes.length;
        }
        else if (stackView && stackView.direction != direction) {
            CGSize intrinsicContentSize = stackView.intrinsicContentSize;
            length = (direction == SRGStackViewDirectionVertical) ? intrinsicContentSize.height : intrinsicContentSize.width;
        }
        else {
            CGSize fittingSize = UILayoutFittingCompressedSize;
            
            if (direction == SRGStackViewDirectionVertical) {
                fittingSize.width = orthogonalLength;
                length = [view srg_systemLayoutSizeFittingSize:fittingSize
                                 withHorizontalFittingPriority:UILayoutPriorityRequired
                                       verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
            }
            else {
                fittingSize.height = orthogonalLength;
                length = [view srg_systemLayoutSizeFittingSize:fittingSize
                                 withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
                                       verticalFittingPriority:UILayoutPriorityRequired].width;
            }
        }
        
        self.view = view;
        self.length = length;
        
        if (attributes.length >= 0.f) {
            self.hugging = NSUIntegerMax;
            self.resistance = NSUIntegerMax;
        }
        else {
            self.hugging = attributes.hugging;
            self.resistance = attributes.resistance;
        }
    }
    return self;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; view: %@; length: %@; hugging: %@; resistance: %@>",
            [self class],
            self,
            self.view,
            @(self.length),
            @(self.hugging),
            @(self.resistance)];
}

@end
