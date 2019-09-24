//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController.h"

NS_ASSUME_NONNULL_BEGIN

@class SRGLetterboxViewController;

@protocol SRGLetterboxViewControllerDelegate <NSObject>

@optional

/**
*  This method is called when the user proactively plays the media suggested during continuous playback.
*/
- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didEngageInContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia;

/**
*  This method is called when the user cancels continuous playback of the suggested media.
*/
- (void)letterboxViewController:(SRGLetterboxViewController *)letterboxViewController didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia;

@end

@interface SRGLetterboxViewController : UIViewController

/**
 *  Instantiate a view controller whose playback is managed by the specified controller. If none is provided a default
 *  one will be automatically created.
 */
- (instancetype)initWithController:(nullable SRGLetterboxController *)controller;

/**
 *  The controller used for playback.
 */
@property (nonatomic, readonly) SRGLetterboxController *controller;

/**
 *  The view controller delegate.
 */
@property (nonatomic, weak) id<SRGLetterboxViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
