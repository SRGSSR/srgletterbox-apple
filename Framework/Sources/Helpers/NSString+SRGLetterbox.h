//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SRGLetterbox)

/**
 *  Return the receiver with the first letter changed to uppercase (does not alter the other letters).
 */
@property (nonatomic, readonly, copy) NSString *srg_localizedUppercaseFirstLetterString;

@end

NS_ASSUME_NONNULL_END
