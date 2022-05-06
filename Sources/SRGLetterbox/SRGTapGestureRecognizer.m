//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTapGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

const NSTimeInterval SRGTapGestureRecognizerDelay = 0.5;

static void commonInit(SRGTapGestureRecognizer *self);

@implementation SRGTapGestureRecognizer

#pragma mark Object lifecycle

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    if (self = [super initWithTarget:target action:action]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    commonInit(self);
}

#pragma mark Subclassing hooks

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failIfNotRecognized) object:nil];
    [self performSelector:@selector(failIfNotRecognized) withObject:nil afterDelay:self.tapDelay inModes:@[ NSRunLoopCommonModes ]];
}

#pragma mark Helpers

- (void)failIfNotRecognized
{
    if (self.state != UIGestureRecognizerStateRecognized) {
        self.state = UIGestureRecognizerStateFailed;
    }
}

@end

#pragma mark Functions

static void commonInit(SRGTapGestureRecognizer *self)
{
    self.tapDelay = SRGTapGestureRecognizerDelay;
}
