//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (SRGLetterbox)

/**
 *  Use this method to display the correct availability label for a media
 */
- (void)srg_displayAvailabilityLabelForMedia:(nullable SRGMedia *)media;

@end

NS_ASSUME_NONNULL_END
