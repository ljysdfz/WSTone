//
//  WSPlayingTone.m
//  TestIOS
//
//  Created by 黎靖阳 on 1/2/17.
//  Copyright © 2017 Telecom. All rights reserved.
//

#import "WSPlayingTone.h"
#import "WSToneManager+Private.h"
#import "WSToneUtil.h"
#import "WSMuteDetector.h"

///重复振动回调方法
void WSPlayingToneVibrateRepeatedly(SystemSoundID sound, void *clientData) {
    dispatch_block_t replayBlock = (__bridge dispatch_block_t)clientData;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), replayBlock);
}

///振动一次回调方法
void WSPlayingToneVibrateOnce(SystemSoundID sound, void *clientData) {
    WSPlayingTone *tone = (__bridge WSPlayingTone *)clientData;
    [tone stop];
}

@implementation WSPlayingTone {
    ///用于接收tone的生命周期消息的<WSPlayingToneDelegate>委托对象
    __weak id<WSPlayingToneDelegate> _toneDelegate;
    ///每个Playing tone都有一份专属player用于播放自己的声音
    AVAudioPlayer *_audioPlayer;
    ///是否重复执行
    BOOL _isRepeated;
    ///执行重复播放tone的逻辑
    dispatch_block_t _replayBlock;
    ///是否正在播放
    BOOL _isPlaying;
}

- (instancetype)initWithSoundData:(NSData *)soundData
                      isAmbitious:(BOOL)isAmbitious
                       isRepeated:(BOOL)isRepeated
                    vibrateOnRing:(BOOL)vibrateOnRing
          resumeAfterInterruption:(BOOL)resumeAfterInterruption
                     toneDelegate:(nullable id<WSPlayingToneDelegate>)toneDelegate {
    if (!soundData) return nil;
    self = [super init];
    if (self) {
        _audioPlayer = ({
            AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:soundData error:nil];
            audioPlayer.delegate = self;
            if (isRepeated) audioPlayer.numberOfLoops = -1;
            audioPlayer;
        });
        self.isAmbitious = isAmbitious;
        self.vibrateOnRing = vibrateOnRing;
        self.resumeAfterInterruption = resumeAfterInterruption;
        _isRepeated = isRepeated;
        _toneDelegate = toneDelegate;
        _replayBlock = dispatch_block_create(DISPATCH_BLOCK_DETACHED, ^{[WSToneUtil vibrateOnce];});
    }
    return self;
}

- (instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    return [self initWithSoundData:nil
                       isAmbitious:NO
                        isRepeated:NO
                     vibrateOnRing:NO
           resumeAfterInterruption:NO
                      toneDelegate:nil];
#pragma clang diagnostic pop
}

#pragma mark - AVAudioPlayerDelegate

/*
 1.直接播放AMR等不支持的格式不会回调-[WSPlayingTone audioPlayerDecodeErrorDidOccur:error:]方法
 也不会触发flag=NO的-[WSPlayingTone audioPlayerDidFinishPlaying:successfully:]方法
 2.调用[_audioPlayer stop]停止tone不会回调-[WSPlayingTone audioPlayerDidFinishPlaying:successfully:]方法，
 只有自动播放完毕后才会触发回调。
 */

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) [self stop];
    else {
        typeof(self) __autoreleasing autoreleasingSelf = self;
        [autoreleasingSelf abort];
        [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
        [autoreleasingSelf didAbort];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    typeof(self) __autoreleasing autoreleasingSelf = self;
    [autoreleasingSelf abort];
    [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
    [autoreleasingSelf didAbort];
}

#pragma mark - Tone life cycle

- (void)didStart {
    if ([_toneDelegate respondsToSelector:@selector(didStartPlayingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didStartPlayingTone:self];});
    }
}

- (void)didStopWithData:(NSData *)data {
    if ([_toneDelegate respondsToSelector:@selector(didStopPlayingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didStopPlayingTone:self];});
    }
}

- (void)didPause {
    if ([_toneDelegate respondsToSelector:@selector(didPausePlayingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didPausePlayingTone:self];});
    }
}

- (void)didResume {
    if ([_toneDelegate respondsToSelector:@selector(didResumePlayingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didResumePlayingTone:self];});
    }
}

- (void)didAbort {
    if ([_toneDelegate respondsToSelector:@selector(didAbortPlayingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didAbortPlayingTone:self];});
    }
}

#pragma mark - Session

- (BOOL)initSession {
    BOOL result = YES;
    NSError *error = nil;
    result &= [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers|AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:&error];
    result &= [[AVAudioSession sharedInstance] setActive:YES error:&error];
    return result;
}

#pragma mark - Life cycle

- (void)start {[self startWithCompletionHandler:^{[self didStart];}];}

- (void)stop {
    typeof(self) __autoreleasing autoreleasingSelf = self;
    [autoreleasingSelf stopWithIntentionHandler:^{[_audioPlayer stop];}];
    [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
    [autoreleasingSelf didStopWithData:nil];
}

- (void)abort {[self stopWithIntentionHandler:^{[_audioPlayer stop];}];}

- (void)resume {[self startWithCompletionHandler:^{[self didResume];}];}

- (void)pause {
    [self stopWithIntentionHandler:^{[_audioPlayer pause];}];
    [self didPause];
}

#pragma mark - Private method

- (void)startWithCompletionHandler:(dispatch_block_t)completionHandler {
    if (self.isAmbitious) [self playWithCompletionHandler:completionHandler];
    else [WSMuteDetector detectMuteSwitchWithCompletion:^(BOOL isMute) {
        if (isMute) {
            if (_isRepeated) [self vibrateRepeatedly];
            else [self vibrateOnce];
            !completionHandler ?: completionHandler();
        } else [self playWithCompletionHandler:completionHandler];
    }];
}

- (void)playWithCompletionHandler:(dispatch_block_t)completionHandler {
    if ([self initSession] && [_audioPlayer play]) {
        _isPlaying = YES;
        if (self.vibrateOnRing) [self vibrateRepeatedly];
        !completionHandler ?: completionHandler();
    } else {
        typeof(self) __autoreleasing autoreleasingSelf = self;
        [autoreleasingSelf abort];
        [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
        [autoreleasingSelf didAbort];
    }
}

- (void)vibrateRepeatedly {
    self.isVibrating = YES;
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, WSPlayingToneVibrateRepeatedly, (__bridge void *)_replayBlock);
    [WSToneUtil vibrateOnce];
}

- (void)vibrateOnce {
    self.isVibrating = YES;
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, WSPlayingToneVibrateOnce, (__bridge void *)self);
    [WSToneUtil vibrateOnce];
}

- (void)stopWithIntentionHandler:(dispatch_block_t)intentionHandler {
    if (_isPlaying) {
        !intentionHandler ?: intentionHandler();
        [self deinitSession];
        _isPlaying = NO;
    }
    if (self.isVibrating) {
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
        dispatch_block_cancel(_replayBlock);
        self.isVibrating = NO;
    }
}

@end
