//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGDataProvider+SRGLetterbox.h"

static NSURL *s_serviceURL;

NSString *SRGDataProviderBusinessUnitIdentifierForVendor(SRGVendor vendor)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @(SRGVendorRSI) : SRGDataProviderBusinessUnitIdentifierRSI,
                                                                                         @(SRGVendorRTR) : SRGDataProviderBusinessUnitIdentifierRTR,
                                                                                         @(SRGVendorRTS) : SRGDataProviderBusinessUnitIdentifierRTS,
                                                                                         @(SRGVendorSRF) : SRGDataProviderBusinessUnitIdentifierSRF,
                                                                                         @(SRGVendorSWI) : SRGDataProviderBusinessUnitIdentifierSWI }
                                                                         defaultValue:nil
                                                                  reverseDefaultValue:nil];
    });
    return [s_transformer transformedValue:@(vendor)];
}


@implementation SRGDataProvider (SRGLetterbox)

+ (NSURL *)serviceURL
{
    return s_serviceURL ?: [self currentDataProvider] ? [self currentDataProvider].serviceURL : SRGIntegrationLayerProductionServiceURL();
}

+ (void)setServiceURL:(NSURL *)serviceURL
{
    s_serviceURL = serviceURL;
}

@end
