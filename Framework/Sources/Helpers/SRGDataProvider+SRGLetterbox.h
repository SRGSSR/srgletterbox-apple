//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return the data provider business unit identifier matching a specific vendor
 */
OBJC_EXPORT NSString *SRGDataProviderBusinessUnitIdentifierForVendor(SRGVendor vendor);

@interface SRGDataProvider (SRGLetterbox)

/**
 *  With the SRGLetterbox framework, if you play a media or an URN with SRGLetterboxService, Letterbox use the correct
 *  BU DataProvider and use this service URL property.
 *
 *  By default, or anything is set, tthe IL production service, SRGIntegrationLayerProductionServiceURL() is returned.
 *  If you set a current SRGDataProvider with `+setCurrentDataProvider:`, it returns its serviceURL.
 *  If you set a service URL with `+setServiceURL:`, this one will be returned.
 *
 *  @see `+setServiceURL:`
 */
+ (NSURL *)serviceURL;

/**
 *  Force the service URL to used with SRGLetterBox framework.
 *
 *  @discussion Do it before calling a play mehtod on SRGLetterboxService
 */
+ (void)setServiceURL:(nullable NSURL *)serviceURL;

@end

NS_ASSUME_NONNULL_END
