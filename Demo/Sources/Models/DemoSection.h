//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Demo sections
 */
typedef NS_ENUM(NSInteger, DemoSectionId) {
#if TARGET_OS_IOS
    DemoSectionIdBasicPlayer = 0,
    DemoSectionIdStandalonePlayer,
    DemoSectionIdSRGSSRContent,
#else
    DemoSectionIdSRGSSRContent = 0,
#endif
    DemoSectionIdSpecialCases,
#if TARGET_OS_IOS
    DemoSectionIdMultiplePlayer,
    DemoSectionIdAutoplay,
#endif
    DemoSectionIdMediaLists,
    DemoSectionIdTopicLists,
#if TARGET_OS_IOS
    DemoSectionIdPlaylists,
    DemoSectionIdPagenavigation,
#endif
    DemoSectionIdMax
};

@interface DemoSection : NSObject

@property(class, nonatomic, readonly) NSArray<DemoSection *> *homeSections;

@property (nonatomic, readonly) DemoSectionId sectionId;
@property (nonatomic, readonly, copy) NSString *headerTitle;
@property (nonatomic, readonly, copy) NSString *footerTitle;

@end

NS_ASSUME_NONNULL_END
