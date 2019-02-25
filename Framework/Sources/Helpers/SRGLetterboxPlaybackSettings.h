//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Settings to be applied when performing resource lookup retrieval for media playback. Resource lookup attempts
 *  to find a close match for a set of settings.
 */
@interface SRGLetterboxPlaybackSettings : NSObject

/**
 *  The stream type to use. Default value is `SRGStreamTypeNone`.
 *
 *  @discussion If `SRGStreamTypeNone` or if no matching resource is found during resource lookup, a recommended
 *              method is used instead.
 */
@property (nonatomic) SRGStreamType streamType;

/**
 *  The quality to use. Default value is `SRGQualityNone`.
 *
 *  @discussion If `SRGQualityNone` or if no matching resource is found during resource lookup, the best available
 *              quality is used instead.
 */
@property (nonatomic) SRGQuality quality;

/**
 *  The bit rate the media should start playing with, in kbps. This parameter is a recommendation with no result guarantee,
 *  though it should in general be applied. The nearest available quality (larger or smaller than the requested size) is
 *  used.
 *
 *  Usual SRG SSR valid bit ranges vary from 100 to 3000 kbps. Use 0 to start with the lowest quality stream.
 *
 *  Default value is `SRGDefaultStartBitRate`.
 */
@property (nonatomic) NSUInteger startBitRate;

/**
 *  If set to `NO`, the content is played in the context of its full length media. If set to `YES`, the content is played
 *  standalone.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isStandalone) BOOL standalone;

/**
 *  Optional playback source unique id.
 */
@property (nonatomic, nullable) NSString *sourceUid;

@end

NS_ASSUME_NONNULL_END
