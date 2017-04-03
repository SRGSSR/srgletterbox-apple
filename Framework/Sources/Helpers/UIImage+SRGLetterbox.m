//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+SRGLetterbox.h"

#import "NSBundle+SRGLetterbox.h"

CGSize SRGSizeForImageScale(SRGImageScale imageScale)
{
    static NSDictionary *s_widths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            s_widths = @{ @(SRGImageScaleSmall) : @(200.f),
                          @(SRGImageScaleMedium) : @(350.f),
                          @(SRGImageScaleLarge) : @(500.f)};
        }
        else {
            s_widths = @{ @(SRGImageScaleSmall) : @(200.f),
                          @(SRGImageScaleMedium) : @(500.f),
                          @(SRGImageScaleLarge) : @(1000.f)};
        }
    });
    
    // Use 2x maximum as scale. Sufficient for a good result without having to load very large images
    CGFloat width = [s_widths[@(imageScale)] floatValue] * fminf([UIScreen mainScreen].scale, 2.f);
    return CGSizeMake(width, width * 9.f / 16.f);
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
+ (UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(nullable NSBundle *)bundle withSize:(CGSize)size
{
    static NSCache<NSString *, UIImage *> *s_cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cache = [[NSCache alloc] init];
    });
    
    if (!bundle) {
        bundle = [NSBundle mainBundle];
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

+ (UIImage *)srg_vectorImageNamed:(NSString *)imageName inBundle:(nullable NSBundle *)bundle withScale:(SRGImageScale)imageScale
{
    CGSize size = SRGSizeForImageScale(imageScale);
    return [self srg_vectorImageNamed:imageName inBundle:bundle withSize:size];
}

+ (UIImage *)srg_letterboxImageNamed:(NSString *)imageName
{
    return [UIImage imageNamed:imageName inBundle:[NSBundle srg_letterboxBundle] compatibleWithTraitCollection:nil];
}

- (UIImage *)srg_imageTintedWithColor:(UIColor *)color
{
    if (!color) {
        return self;
    }
    
    CGRect rect = CGRectMake(0.f, 0.f, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0.f, self.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    CGContextDrawImage(context, rect, self.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end
