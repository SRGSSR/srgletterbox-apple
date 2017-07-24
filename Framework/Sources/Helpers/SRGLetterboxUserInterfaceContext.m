//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxUserInterfaceContext.h"

@interface SRGLetterboxUserInterfaceContext ()

@property (nonatomic, copy) NSString *identifier;

@end

@implementation SRGLetterboxUserInterfaceContext

#pragma mark Object lifecycle

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        self.identifier = identifier;
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
    
    SRGLetterboxUserInterfaceContext *otherRestorationContext = object;
    return [self.identifier isEqualToString:otherRestorationContext.identifier];
}

- (NSUInteger)hash
{
    return self.identifier.hash;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; hidden: %@; togglable: %@; identifier: %@>",
            [self class],
            self,
            self.hidden ? @"YES" : @"NO",
            self.togglable ? @"YES" : @"NO",
            self.identifier];
}

@end
