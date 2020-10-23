//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+SRGLetterbox.h"

#import "NSError+SRGLetterbox.h"
#import "SRGLetterboxError.h"

static BOOL SRGLetterboxIsValidURL(NSURL * _Nullable URL)
{
    // Fix for invalid images, incorrect Kids program images, and incorrect images for sports (RTS)
    // See https://srfmmz.atlassian.net/browse/AIS-15672
    return URL && ! [URL.absoluteString containsString:@"NOT_SPECIFIED.jpg"] && ! [URL.absoluteString containsString:@"rts.ch/video/jeunesse"]
    && ! [URL.absoluteString containsString:@".html"];
}

NSString *SRGLetterboxFilePathForImagePlaceholder(void)
{
#if TARGET_OS_TV
    return [SWIFTPM_MODULE_BUNDLE pathForResource:@"placeholder~tvos" ofType:@"pdf"];
#else
    return [SWIFTPM_MODULE_BUNDLE pathForResource:@"placeholder" ofType:@"pdf"];
#endif
}

NSURL *SRGLetterboxImageURL(id<SRGImage> object, CGFloat width, SRGImageType type)
{
    if (! object) {
        return nil;
    }
    
    NSURL *URL = [object imageURLForDimension:SRGImageDimensionWidth withValue:width type:type];
    if (! SRGLetterboxIsValidURL(URL)) {
        return nil;
    }
    
    return URL;
}

NSURL *SRGLetterboxArtworkImageURL(id<SRGImage> object, CGFloat dimension)
{
    NSURL *imageURL = SRGLetterboxImageURL(object, dimension, SRGImageTypeDefault);
    if (! imageURL) {
        return nil;
    }
    
    NSString *squareArtworkURLString = [NSString stringWithFormat:@"https://il.srgssr.ch/integrationlayer/2.0/image-scale-one-to-one/%@/scale/width/%.0f", imageURL.absoluteString, dimension];
    return [NSURL URLWithString:squareArtworkURLString];
}

CGFloat SRGWidthForImageScale(SRGImageScale imageScale)
{
    static NSDictionary *s_widths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
#if TARGET_OS_TV
        s_widths = @{ @(SRGImageScaleSmall) : @(400.f),
                      @(SRGImageScaleMedium) : @(800.f),
                      @(SRGImageScaleLarge) : @(1920.f)};
#else
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            s_widths = @{ @(SRGImageScaleSmall) : @(200.f),
                          @(SRGImageScaleMedium) : @(350.f),
                          @(SRGImageScaleLarge) : @(500.f)};
        }
        else {
            s_widths = @{ @(SRGImageScaleSmall) : @(200.f),
                          @(SRGImageScaleMedium) : @(500.f),
                          @(SRGImageScaleLarge) : @(1000.f)};
        }
#endif
    });
    
    // Use 2x maximum as scale. Sufficient for a good result without having to load very large images
    return [s_widths[@(imageScale)] floatValue] * fminf(UIScreen.mainScreen.scale, 2.f);
}

static CGFloat SRGImageAspectScaleFit(CGSize sourceSize, CGRect destRect)
{
    CGSize destSize = destRect.size;
    CGFloat scaleW = destSize.width / sourceSize.width;
    CGFloat scaleH = destSize.height / sourceSize.height;
    return fmin(scaleW, scaleH);
}

static CGRect SRGImageRectAroundCenter(CGPoint center, CGSize size)
{
    return CGRectMake(center.x - size.width / 2.f, center.y - size.height / 2.f, size.width, size.height);
}

static CGRect SRGImageRectByFittingRect(CGRect sourceRect, CGRect destinationRect)
{
    CGFloat aspect = SRGImageAspectScaleFit(sourceRect.size, destinationRect);
    CGSize targetSize = CGSizeMake(sourceRect.size.width * aspect, sourceRect.size.height * aspect);
    CGPoint center = CGPointMake(CGRectGetMidX(destinationRect), CGRectGetMidY(destinationRect));
    return SRGImageRectAroundCenter(center, targetSize);
}

static void SRGImageDrawPDFPageInRect(CGPDFPageRef pageRef, CGRect rect)
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Flip the context to Quartz space
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1.f, -1.f);
    transform = CGAffineTransformTranslate(transform, 0.f, -image.size.height);
    CGContextConcatCTM(context, transform);
    
    // Flip the rect, which remains in UIKit space
    CGRect d = CGRectApplyAffineTransform(rect, transform);
    
    // Calculate a rectangle to draw to
    CGRect pageRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    CGFloat drawingAspect = SRGImageAspectScaleFit(pageRect.size, d);
    CGRect drawingRect = SRGImageRectByFittingRect(pageRect, d);
    
    // Adjust the context
    CGContextTranslateCTM(context, drawingRect.origin.x, drawingRect.origin.y);
    CGContextScaleCTM(context, drawingAspect, drawingAspect);
    
    // Draw the page
    CGContextDrawPDFPage(context, pageRef);
    CGContextRestoreGState(context);
}

@implementation UIImage (SRGLetterbox)

// Implementation borrowed from https://github.com/erica/useful-things
+ (UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(NSBundle *)bundle withSize:(CGSize)size
{
    static NSCache<NSString *, UIImage *> *s_cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cache = [[NSCache alloc] init];
    });
    
    if (!bundle) {
        bundle = NSBundle.mainBundle;
    }
    
    NSString *key = [NSString stringWithFormat:@"%@_%@_%@_%@", imageName, @(size.width), @(size.height), bundle.bundleIdentifier];
    UIImage *cachedImage = [s_cache objectForKey:key];
    if (cachedImage) {
        return cachedImage;
    }
    
    NSURL *fileURL = [bundle URLForResource:imageName withExtension:@"pdf"];
    CGPDFDocumentRef pdfDocumentRef = CGPDFDocumentCreateWithURL((__bridge CFURLRef)fileURL);
    if (! pdfDocumentRef) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdfDocumentRef, 1);
    SRGImageDrawPDFPageInRect(pageRef, CGRectMake(0.f, 0.f, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGPDFDocumentRelease(pdfDocumentRef);
    
    [s_cache setObject:image forKey:key];
    return image;
}

@end

@implementation UIImage (SRGLetterboxImages)

+ (UIImage *)srg_letterboxImageNamed:(NSString *)imageName
{
    return [UIImage imageNamed:imageName inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
}

+ (UIImage *)srg_letterboxPlayImageInSet:(SRGImageSet)imageSet
{
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:@"play"] : [UIImage srg_letterboxImageNamed:@"play-large"];
}

+ (UIImage *)srg_letterboxPauseImageInSet:(SRGImageSet)imageSet
{
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:@"pause"] : [UIImage srg_letterboxImageNamed:@"pause-large"];
}

+ (UIImage *)srg_letterboxStopImageInSet:(SRGImageSet)imageSet
{
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:@"stop"] : [UIImage srg_letterboxImageNamed:@"stop-large"];
}

+ (UIImage *)srg_letterboxSeekForwardImageInSet:(SRGImageSet)imageSet
{
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:@"forward"] : [UIImage srg_letterboxImageNamed:@"forward-large"];
}

+ (UIImage *)srg_letterboxSeekBackwardImageInSet:(SRGImageSet)imageSet
{
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:@"backward"] : [UIImage srg_letterboxImageNamed:@"backward-large"];
}

+ (UIImage *)srg_letterboxStartOverImageInSet:(SRGImageSet)imageSet
{
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:@"start_over"] : [UIImage srg_letterboxImageNamed:@"start_over-large"];
}

+ (UIImage *)srg_letterboxSkipToLiveImageInSet:(SRGImageSet)imageSet
{
    // TODO: Localization catalogs can be used for image localization, but for iOS 12 and above. Here we can preserve iOS 9
    //       compatibility with a simple trick, as we have a single FR resource at the moment.
    //       See https://developer.apple.com/videos/play/wwdc2018/404/
    NSString *imageName = [NSBundle.mainBundle.preferredLocalizations.firstObject isEqualToString:@"fr"] ? @"back_live_fr" : @"back_live";
    return (imageSet == SRGImageSetNormal) ? [UIImage srg_letterboxImageNamed:imageName] : [UIImage srg_letterboxImageNamed:[imageName stringByAppendingString:@"-large"]];
}

+ (UIImage *)srg_letterboxImageForError:(NSError *)error
{
    if (! error) {
        return nil;
    }
    
    if (error.srg_letterboxNoNetworkError) {
        return [UIImage srg_letterboxImageNamed:@"no_network"];
    }
    else if ([error.domain isEqualToString:SRGLetterboxErrorDomain]) {
        NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
        if (error.code == SRGLetterboxErrorCodeBlocked) {
            SRGBlockingReason blockingReason = [error.userInfo[SRGLetterboxBlockingReasonKey] integerValue];
            return [self srg_letterboxImageForBlockingReason:blockingReason];
        }
        else {
            return [UIImage srg_letterboxImageNamed:@"generic_error"];
        }
    }
    else {
        return [UIImage srg_letterboxImageNamed:@"generic_error"];
    }
}

+ (UIImage *)srg_letterboxImageForBlockingReason:(SRGBlockingReason)blockingReason
{
    switch (blockingReason) {
        case SRGBlockingReasonGeoblocking: {
            return [UIImage srg_letterboxImageNamed:@"geoblocked"];
            break;
        }
            
        case SRGBlockingReasonLegal: {
            return [UIImage srg_letterboxImageNamed:@"legal"];
            break;
        }
            
        case SRGBlockingReasonAgeRating12:
        case SRGBlockingReasonAgeRating18: {
            return [UIImage srg_letterboxImageNamed:@"age_rating"];
            break;
        }
            
        case SRGBlockingReasonStartDate:
        case SRGBlockingReasonEndDate:
        case SRGBlockingReasonNone: {
            return nil;
            break;
        }
            
        default: {
            return [UIImage srg_letterboxImageNamed:@"generic_blocked"];
            break;
        }
    }
}

@end
