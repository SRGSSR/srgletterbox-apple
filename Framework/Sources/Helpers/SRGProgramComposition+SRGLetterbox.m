//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgramComposition+SRGLetterbox.h"

#import "SRGProgram+SRGLetterbox.h"

@implementation SRGProgramComposition (SRGLetterbox)

- (SRGProgram *)letterbox_programAtDate:(NSDate *)date
{
    if (! date) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGProgram * _Nullable program, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [program srgletterbox_containsDate:date];
    }];
    return [self.programs filteredArrayUsingPredicate:predicate].lastObject;
}

@end
