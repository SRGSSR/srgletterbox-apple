//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGStackView.h"

#import "SRGStackItem.h"
#import "UIView+SRGStackView.h"

#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface NSArray (SRGStackView)

- (NSArray *)srg_arrayByAddingObjectsFromArray:(NSArray *)array;
- (NSArray *)srg_arrayByRemovingObjectsInArray:(NSArray *)array;

@end

@implementation NSArray (SRGStackView)

- (NSArray *)srg_arrayByAddingObjectsFromArray:(NSArray *)array
{
    NSMutableArray *editedArray = [self mutableCopy];
    [editedArray addObjectsFromArray:array];
    return [editedArray copy];
}

- (NSArray *)srg_arrayByRemovingObjectsInArray:(NSArray *)array
{
    NSMutableArray *editedArray = [self mutableCopy];
    [editedArray removeObjectsInArray:array];
    return [editedArray copy];
}

@end

@implementation SRGStackAttributes

- (instancetype)init
{
    if (self = [super init]) {
        self.length = -1.f;
        self.hugging = 250;
        self.resistance = 250;
    }
    return self;
}

@end

@implementation SRGStackView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat orthogonalLength = (self.direction == SRGStackViewDirectionVertical) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
    NSArray<SRGStackItem *> *stackItems = [SRGStackItem stackItemsForViews:self.subviews withDirection:self.direction orthogonalLength:orthogonalLength];
    CGFloat length = [[stackItems valueForKeyPath:@"@sum.length"] floatValue] + (stackItems.count - 1) * self.spacing;
    CGFloat availableLength = (self.direction == SRGStackViewDirectionVertical) ? CGRectGetHeight(self.frame) : CGRectGetWidth(self.frame);
    if (length <= availableLength) {
        NSNumber *smallestHugging = [stackItems valueForKeyPath:@"@min.hugging"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hugging == %@", smallestHugging];
        
        NSArray<SRGStackItem *> *expandedItems = [stackItems filteredArrayUsingPredicate:predicate];
        CGFloat increment = (availableLength - length) / expandedItems.count;
        
        CGFloat position = 0.f;
        for (SRGStackItem *item in stackItems) {
            CGFloat length = item.length;
            if ([expandedItems containsObject:item]) {
                length += increment;
            }
            item.view.frame = (self.direction == SRGStackViewDirectionVertical) ? CGRectMake(0.f, position, CGRectGetWidth(self.frame), length) : CGRectMake(position, 0.f, length, CGRectGetHeight(self.frame));
            position += length + self.spacing;
        }
    }
    else {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"floatValue" ascending:NO];
        NSArray<NSNumber *> *resistances = [[stackItems valueForKeyPath:@"@distinctUnionOfObjects.resistance"] sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        NSArray<SRGStackItem *> *compressedItems = nil;
        NSArray<SRGStackItem *> *fixedItems = [NSArray array];
        CGFloat decrement = 0.f;
        
        for (NSNumber *resistance in resistances) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resistance == %@", resistance];
            NSArray *resistanceItems = [stackItems filteredArrayUsingPredicate:predicate];
            
            CGFloat resistanceLength = [[resistanceItems valueForKeyPath:@"@sum.length"] floatValue];
            
            if (resistanceLength <= availableLength) {
                fixedItems = [fixedItems srg_arrayByAddingObjectsFromArray:resistanceItems];
                availableLength -= resistanceLength;
            }
            else {
                compressedItems = resistanceItems;
                decrement = (resistanceLength - availableLength) / resistanceItems.count;
                break;
            }
        }
        
        CGFloat position = 0.f;
        for (SRGStackItem *item in stackItems) {
            CGFloat length = item.length;
            if ([compressedItems containsObject:item]) {
                length -= decrement;
            }
            else if (! [fixedItems containsObject:item]) {
                length = 0.f;
            }
            item.view.frame = (self.direction == SRGStackViewDirectionVertical) ? CGRectMake(0.f, position, CGRectGetWidth(self.frame), length) : CGRectMake(position, 0.f, length, CGRectGetHeight(self.frame));
            position += length + self.spacing;
        }
    }
}

- (CGSize)intrinsicContentSize
{
    if (self.direction == SRGStackViewDirectionVertical) {
        CGFloat maximumWidth = 0.f;
        for (UIView *subview in self.subviews) {
            CGFloat width = [subview srg_systemLayoutSizeFittingSize:UILayoutFittingCompressedSize
                                       withHorizontalFittingPriority:UILayoutPriorityRequired
                                             verticalFittingPriority:UILayoutPriorityRequired].width;
            if (width > maximumWidth) {
                maximumWidth = width;
            }
        }
        
        NSArray<SRGStackItem *> *stackItems = [SRGStackItem stackItemsForViews:self.subviews withDirection:self.direction orthogonalLength:maximumWidth];
        CGFloat height = [[stackItems valueForKeyPath:@"@sum.length"] floatValue] + (stackItems.count - 1) * self.spacing;
        return CGSizeMake(maximumWidth, height);
    }
    else {
        CGFloat maximumHeight = 0.f;
        for (UIView *subview in self.subviews) {
            CGFloat height = [subview srg_systemLayoutSizeFittingSize:UILayoutFittingCompressedSize
                                        withHorizontalFittingPriority:UILayoutPriorityRequired
                                              verticalFittingPriority:UILayoutPriorityRequired].height;
            if (height > maximumHeight) {
                maximumHeight = height;
            }
        }
        
        NSArray<SRGStackItem *> *stackItems = [SRGStackItem stackItemsForViews:self.subviews withDirection:self.direction orthogonalLength:maximumHeight];
        CGFloat width = [[stackItems valueForKeyPath:@"@sum.length"] floatValue] + (stackItems.count - 1) * self.spacing;
        return CGSizeMake(width, maximumHeight);
    }
}

- (void)addSubview:(UIView *)view withAttributes:(void (^)(SRGStackAttributes *))attributes
{
    SRGStackAttributes *stackAttributes = [[SRGStackAttributes alloc] init];
    attributes(stackAttributes);
    view.srg_stackAttributes = stackAttributes;
    
    [super addSubview:view];
}

- (void)addSubview:(UIView *)view
{
    [self addSubview:view withAttributes:^(SRGStackAttributes * _Nonnull attributes) {}];
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index withAttributes:(void (^)(SRGStackAttributes *attributes))attributes
{
    SRGStackAttributes *stackAttributes = [[SRGStackAttributes alloc] init];
    attributes(stackAttributes);
    view.srg_stackAttributes = stackAttributes;
    
    [super insertSubview:view atIndex:index];
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index
{
    [self insertSubview:view atIndex:index withAttributes:^(SRGStackAttributes * _Nonnull attributes) {}];
}

- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview withAttributes:(void (^)(SRGStackAttributes *attributes))attributes
{
    SRGStackAttributes *stackAttributes = [[SRGStackAttributes alloc] init];
    attributes(stackAttributes);
    view.srg_stackAttributes = stackAttributes;
    
    [super insertSubview:view belowSubview:siblingSubview];
}

- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview
{
    [self insertSubview:view belowSubview:siblingSubview withAttributes:^(SRGStackAttributes * _Nonnull attributes) {}];
}

- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview withAttributes:(void (^)(SRGStackAttributes *attributes))attributes
{
    SRGStackAttributes *stackAttributes = [[SRGStackAttributes alloc] init];
    attributes(stackAttributes);
    view.srg_stackAttributes = stackAttributes;
    
    [super insertSubview:view aboveSubview:siblingSubview];
}

- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview
{
    [self insertSubview:view aboveSubview:siblingSubview withAttributes:^(SRGStackAttributes * _Nonnull attributes) {}];
}

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
    
    [subview addObserver:self keyPath:@"hidden" options:0 block:^(MAKVONotification *notification) {
        [self setNeedsLayout];
    }];
}

- (void)willRemoveSubview:(UIView *)subview
{
    [super willRemoveSubview:subview];
    
    [subview removeObserver:self keyPath:@"hidden"];
}

// TODO: Should observe subview visibility changes

@end
