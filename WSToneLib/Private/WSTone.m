//
//  WSTone.m
//  MicroVideo
//
//  Created by 黎靖阳 on 12/27/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import "WSToneManager+Private.h"
#import "WSTone.h"
#import "WSTone+Private.h"
#import "WSPlayingTone.h"
#import "WSRecordingTone.h"
#import "amrFileCodec.h"
#import "WSToneUtil.h"

@implementation WSTone

+ (instancetype)playingToneWithSoundURL:(NSURL *)soundURL
                            isAmbitious:(BOOL)isAmbitious
                             isRepeated:(BOOL)isRepeated
                          vibrateOnRing:(BOOL)vibrateOnRing
                resumeAfterInterruption:(BOOL)resumeAfterInterruption
                           toneDelegate:(nullable id<WSPlayingToneDelegate>)toneDelegate {
    NSData *soundData = [NSData dataWithContentsOfURL:soundURL];
    //AMR类型的语音消息先转为iOS可以识别的WAV类型音频
    if ([[soundURL pathExtension].lowercaseString isEqualToString:@"amr"]) soundData = DecodeAMRToWAVE(soundData);
    if (!soundData) return nil;
    return [[WSPlayingTone alloc] initWithSoundData:soundData
                                        isAmbitious:isAmbitious
                                         isRepeated:isRepeated
                                      vibrateOnRing:vibrateOnRing
                            resumeAfterInterruption:resumeAfterInterruption
                                       toneDelegate:toneDelegate];
}

+ (instancetype)playingToneWithSoundData:(NSData *)soundData
                             isAmbitious:(BOOL)isAmbitious
                              isRepeated:(BOOL)isRepeated
                           vibrateOnRing:(BOOL)vibrateOnRing
                 resumeAfterInterruption:(BOOL)resumeAfterInterruption
                            toneDelegate:(nullable id<WSPlayingToneDelegate>)toneDelegate {
    if (!soundData) return nil;
    //AMR类型的语音消息先转为iOS可以识别的WAV类型音频
    if ([WSToneUtil isAMRAudioData:soundData]) soundData = DecodeAMRToWAVE(soundData);
    return [[WSPlayingTone alloc] initWithSoundData:soundData
                                        isAmbitious:isAmbitious
                                         isRepeated:isRepeated
                                      vibrateOnRing:vibrateOnRing
                            resumeAfterInterruption:resumeAfterInterruption
                                       toneDelegate:toneDelegate];
}

+ (instancetype)recordingToneWithToneDelegate:(nullable id<WSRecordingToneDelegate>)toneDelegate {
    return [[WSRecordingTone alloc] initWithToneDelegate:toneDelegate];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSystemInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    }
    return self;
}

- (void)dealloc {[[NSNotificationCenter defaultCenter] removeObserver:self];}

#pragma mark - Tone life cycle

- (void)start {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)stop {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)pause {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)resume {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)abort {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)didStart {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)didStopWithData:(nullable NSData *)data {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)didPause {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)didResume {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}
- (void)didAbort {NSAssert(NO, @"%s must be overrided", __FUNCTION__);}

#pragma mark - Session

- (BOOL)initSession {NSAssert(NO, @"%s must be overrided", __FUNCTION__);return NO;}
- (void)deinitSession {[[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];}

#pragma mark - Notification

/**
 @brief 处理系统高优先级声音入侵
 @param notification 监听到的通知消息
 */
- (void)handleSystemInterruption:(NSNotification *)notification {
    NSNumber *interruptionTypeNumber = notification.userInfo[AVAudioSessionInterruptionTypeKey];
    NSUInteger interruptionType = [interruptionTypeNumber unsignedIntegerValue];
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        if (self.resumeAfterInterruption) [self pause];
        else {
            typeof(self) __autoreleasing autoreleasingSelf = self;
            [autoreleasingSelf abort];
            [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
            [autoreleasingSelf didAbort];
        }
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        NSNumber *interruptionOptionsNumber = notification.userInfo[AVAudioSessionInterruptionOptionKey];
        AVAudioSessionInterruptionOptions interruptionOptions = [interruptionOptionsNumber unsignedIntegerValue];
        if (interruptionOptions == AVAudioSessionInterruptionOptionShouldResume && self.resumeAfterInterruption) [self resume];
    }
}

@end
