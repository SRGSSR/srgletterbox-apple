//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVKit/AVKit.h>
#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(tvos(10.0))
@interface SRGLettterboxContentProposalViewController : AVContentProposalViewController

- (instancetype)initWithController:(SRGLetterboxController *)controller;

@end

@interface SRGLettterboxContentProposalViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
