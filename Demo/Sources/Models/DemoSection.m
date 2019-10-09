//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DemoSection.h"

@interface DemoSection ()

@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *footerTitle;

@end

@implementation DemoSection

+ (NSArray<DemoSection *> *)homeSections
{
    static dispatch_once_t s_onceToken;
    static NSArray<DemoSection *> *s_demoSections;
    dispatch_once(&s_onceToken, ^{
        NSArray<NSString *> *sectionHeaders = @[
#if TARGET_OS_IOS
            NSLocalizedString(@"Basic player", nil),
            NSLocalizedString(@"Standalone player", nil),
#endif
            NSLocalizedString(@"Player with SRGSSR content", nil),
            NSLocalizedString(@"Player with special cases", nil),
#if TARGET_OS_IOS
            NSLocalizedString(@"Multiple player", nil),
            NSLocalizedString(@"Autoplay", nil),
#endif
            NSLocalizedString(@"Media lists", nil),
            NSLocalizedString(@"Topic lists", nil),
#if TARGET_OS_IOS
            NSLocalizedString(@"Playlists", nil),
            NSLocalizedString(@"Page navigation", nil)
#endif
        ];
        
        NSArray<NSString *> *sectionFooters = @[
#if TARGET_OS_IOS
            NSLocalizedString(@"This basic player can be used with AirPlay but does not implement full screen or picture in picture.", nil),
            NSLocalizedString(@"This player is not enabled for AirPlay playback or picture in picture by default. You can enable or disable these features on the fly.", nil),
            NSLocalizedString(@"This player implements full screen and picture in picture and can be used with AirPlay. It starts with hidden controls, and a close button has been added as custom control. You can also play with various user interface configurations.", nil),
#else
            NSLocalizedString(@"This media list use the player designed for the SRGSSR tvOS experience.", nil),
#endif
            NSLocalizedString(@"The player in special cases that can occured.", nil),
#if TARGET_OS_IOS
            NSLocalizedString(@"This player plays three streams at the same time, and can be used with AirPlay and picture in picture. You can tap on a smaller stream to play it as main stream.", nil),
            NSLocalizedString(@"Lists of medias played automatically as they are scrolled.", nil),
#endif
            NSLocalizedString(@"Lists of medias played with the player.", nil),
            NSLocalizedString(@"Lists of topics, whose medias are played with the player.", nil),
#if TARGET_OS_IOS
            NSLocalizedString(@"Medias opened in the context of a playlist.", nil),
            NSLocalizedString(@"Medias displayed in a page navigation.", nil)
#endif
        ];
        
        NSMutableArray<DemoSection *> *demoSections = [NSMutableArray array];
        for (NSUInteger i=0; i < sectionHeaders.count; i++) {
            DemoSection *demoSection = [[DemoSection alloc] init];
            demoSection.headerTitle = sectionHeaders[i];
            demoSection.footerTitle = sectionFooters[i];
            [demoSections addObject:demoSection];
        }
        
        s_demoSections = demoSections.copy;
    });
    
    return s_demoSections;
}

@end
