//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxViewRestorationContext.h"

@interface SRGLetterboxViewRestorationContext ()

@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isTogglable) BOOL togglable;
@property (nonatomic, copy) NSString *name;

@end

@implementation SRGLetterboxViewRestorationContext

#pragma mark Object lifecycle

- (instancetype)initWithLetterboxView:(SRGLetterboxView *)letterboxView name:(NSString *)name
{
    if (self = [super init]) {
        self.hidden = letterboxView.userInterfaceHidden;
        self.togglable = letterboxView.userInterfaceTogglable;
        self.name = name;
    }
    return self;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object
{
    if (! object) {
        return NO;
    }
    
    if (! [object isKindOfClass:[self class]]) {
        return NO;
    }
    
    SRGLetterboxViewRestorationContext *otherRestorationContext = object;
    return [self.name isEqualToString:otherRestorationContext.name];
}

- (NSUInteger)hash
{
    return self.name.hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; hidden: %@; togglable: %@; name: %@>",
            [self class],
            self,
            self.hidden ? @"YES" : @"NO",
            self.togglable ? @"YES" : @"NO",
            self.name];
}

@end
