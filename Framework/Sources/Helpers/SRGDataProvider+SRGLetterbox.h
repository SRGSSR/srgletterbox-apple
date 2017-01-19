//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSString *SRGDataProviderBusinessUnitIdentifierForVendor(SRGVendor vendor);

@interface SRGDataProvider (SRGLetterbox)

/**
 *  With SRGLetterboxService, if you play a media or an URN, Letterbox use the correct BU DataProvider,
 *  and use this default service URL. By default, it's the IL production service, SRGIntegrationLayerProductionServiceURL()
 *
 *  @see `-setDefaultServiceURL:`
 */
+ (NSURL *)defaultServiceURL;

/**
 *  Change the default service URL.
 *
 *  @discussion Do it before calling a play mehtod on SRGLetterboxService
 */
+ (void)setDefaultServiceURL:(NSURL *)defaultServiceURL;

@end

NS_ASSUME_NONNULL_END
