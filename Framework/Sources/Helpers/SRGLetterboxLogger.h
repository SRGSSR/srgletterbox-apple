//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLogger/SRGLogger.h>

/**
 *  Macros for logging.
 */
#define SRGLetterboxLogVerbose(category, format, ...) SRGLogVerbose(@"ch.srgssr.letterbox", category, format, ##__VA_ARGS__)
#define SRGLetterboxLogDebug(category, format, ...)   SRGLogDebug(@"ch.srgssr.letterbox", category, format, ##__VA_ARGS__)
#define SRGLetterboxLogInfo(category, format, ...)    SRGLogInfo(@"ch.srgssr.letterbox", category, format, ##__VA_ARGS__)
#define SRGLetterboxLogWarning(category, format, ...) SRGLogWarning(@"ch.srgssr.letterbox", category, format, ##__VA_ARGS__)
#define SRGLetterboxLogError(category, format, ...)   SRGLogError(@"ch.srgssr.letterbox", category, format, ##__VA_ARGS__)
