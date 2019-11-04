//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Media lists
 */
typedef NS_ENUM(NSInteger, MediaList) {
    /**
     *  Not specified
     */
    MediaListUnknown = 0,
    /**
     *  Live center SRF
     */
    MediaListLiveCenterSRF,
    /**
     *  Live center RTS
     */
    MediaListLiveCenterRTS,
    /**
     *  Live center RSI
     */
    MediaListLiveCenterRSI,
    /**
     *  Latest by topic
     */
    MediaListLatestByTopic,
    /**
     *  Live TV SRF
     */
    MediaListLiveTVSRF,
    /**
     *  Live TV RTS
     */
    MediaListLiveTVRTS,
    /**
     *  Live TV RSI
     */
    MediaListLiveTVRSI,
    /**
     *  Live TV RTR
     */
    MediaListLiveTVRTR,
    /**
     *  Live Radio SRF
     */
    MediaListLiveRadioSRF,
    /**
     *  Live Radio RTS
     */
    MediaListLiveRadioRTS,
    /**
     *  Live Radio RSI
     */
    MediaListLiveRadioRSI,
    /**
     *  Live Radio RTR
     */
    MediaListLiveRadioRTR,
    /**
     *  Latest videos SRF
     */
    MediaListLatestVideosSRF,
    /**
     *  Latest videos RTS
     */
    MediaListLatestVideosRTS,
    /**
     *  Latest videos RSI
     */
    MediaListLatestVideosRSI,
    /**
     *  Latest videos RTR
     */
    MediaListLatestVideosRTR,
    /**
     *  Latest videos SWI
     */
    MediaListLatestVideosSWI,
    /**
     *  Latest audios SRF 1
     */
    MediaListLatestAudiosSRF1,
    /**
     *  Latest audios SRF 2
     */
    MediaListLatestAudiosSRF2,
    /**
     *  Latest audios SRF 3
     */
    MediaListLatestAudiosSRF3,
    /**
     *  Latest audios SRF 4
     */
    MediaListLatestAudiosSRF4,
    /**
     *  Latest audios SRF 5
     */
    MediaListLatestAudiosSRF5,
    /**
     *  Latest audios SRF 6
     */
    MediaListLatestAudiosSRF6,
    /**
     *  Latest audios RTS 1
     */
    MediaListLatestAudiosRTS1,
    /**
     *  Latest audios RTS 2
     */
    MediaListLatestAudiosRTS2,
    /**
     *  Latest audios RTS 3
     */
    MediaListLatestAudiosRTS3,
    /**
     *  Latest audios RTS 4
     */
    MediaListLatestAudiosRTS4,
    /**
     *  Latest audios RTS 5
     */
    MediaListLatestAudiosRTS5,
    /**
     *  Latest audios RSI 1
     */
    MediaListLatestAudiosRSI1,
    /**
     *  Latest audios RSI 2
     */
    MediaListLatestAudiosRSI2,
    /**
     *  Latest audios RSI 3
     */
    MediaListLatestAudiosRSI3,
    /**
     *  Latest audios RTR
     */
    MediaListLatestAudiosRTR,
    /**
     *  Live web SRF
     */
    MediaListLiveWebSRF,
    /**
     *  Live web RTS
     */
    MediaListLiveWebRTS,
    /**
     *  Live web RSI
     */
    MediaListLiveWebRSI,
    /**
     *  Live web RTR
     */
    MediaListLiveWebRTR
};

@interface MediaListViewController : UITableViewController

- (instancetype)initWithMediaList:(MediaList)mediaList topic:(nullable SRGTopic *)topic serviceURL:(nullable NSURL *)serviceURL;

@property (nonatomic, readonly) MediaList mediaList;

@property (nonatomic, readonly, nullable) SRGTopic *topic;

@end

NS_ASSUME_NONNULL_END
