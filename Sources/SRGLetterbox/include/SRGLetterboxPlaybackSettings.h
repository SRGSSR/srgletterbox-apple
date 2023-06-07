//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalyticsDataProvider;

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
 *  If set to `NO`, the content is played in the context of its full length media. If set to `YES`, the content is played
 *  standalone.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isStandalone) BOOL standalone;

/**
 *  A source unique identifier to be associated with the playback. This can be used to convey information about where
 *  the media was retrieved from (e.g. a media list identifier).
 */
@property (nonatomic, copy, nullable) NSString *sourceUid;

@end

NS_ASSUME_NONNULL_END
