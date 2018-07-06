//
//  WSRecordingTone.m
//  TestIOS
//
//  Created by 黎靖阳 on 1/2/17.
//  Copyright © 2017 Telecom. All rights reserved.
//

#import "WSRecordingTone.h"
#import "WSToneManager+Private.h"
#import "WSTone+Private.h"
#import "amrFileCodec.h"
#import "WSToneUtil.h"

///最大录音时长
NSTimeInterval const kWSRecordingToneMaxRecordDuration = 60.0;

@implementation WSRecordingTone {
    ///用于接收tone的生命周期消息的<WSRecordingToneDelegate>委托对象
    __weak id<WSRecordingToneDelegate> _toneDelegate;
    ///每个Recording tone都有一份专属recorder用于录制自己的声音
    AVAudioRecorder *_audioRecorder;
    ///是否产生了有效的录音
    BOOL _hasValidRecord;
}

- (instancetype)initWithToneDelegate:(id<WSRecordingToneDelegate>)toneDelegate {
    self = [super init];
    if (self) {
        _audioRecorder = ({
            NSMutableDictionary *settings = [NSMutableDictionary dictionary];
            //录音格式
            [settings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
            //采样率(WAVE)
            [settings setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];
            //通道数
            [settings setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
            //音频质量,采样质量
            [settings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
            [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];
            [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
            [settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
            //录音数据写入的目标文件地址
            NSURL *destinationURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.wav"]];
            AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:destinationURL settings:settings error:nil];
            recorder.meteringEnabled = YES;
            recorder.delegate = self;
            recorder;
        });
        _toneDelegate = toneDelegate;
    }
    return self;
}

- (instancetype)init {return [self initWithToneDelegate:nil];}

#pragma mark - Accessor

- (BOOL)isAmbitious {return YES;}
- (BOOL)vibrateOnRing {return NO;}
- (BOOL)resumeAfterInterruption {return NO;}
- (BOOL)isVibrating {return NO;}

#pragma mark - Tone life cycle

- (void)didStart {
    if ([_toneDelegate respondsToSelector:@selector(didStartRecordingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didStartRecordingTone:self];});
    }
}

- (void)didStopWithData:(NSData *)data {
    if ([_toneDelegate respondsToSelector:@selector(didStopRecordingTone:withData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_toneDelegate didStopRecordingTone:self withData:data];
        });
    }
}

- (void)didPause {
    if ([_toneDelegate respondsToSelector:@selector(didPauseRecordingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didPauseRecordingTone:self];});
    }
}

- (void)didResume {
    if ([_toneDelegate respondsToSelector:@selector(didResumeRecordingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didResumeRecordingTone:self];});
    }
}

- (void)didAbort {
    if ([_toneDelegate respondsToSelector:@selector(didAbortPlayingTone:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{[_toneDelegate didAbortRecordingTone:self];});
    }
}

#pragma mark - Session

- (BOOL)initSession {
    BOOL result = YES;
    NSError *error = nil;
    result &= [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
    result &= [[AVAudioSession sharedInstance] setActive:YES error:&error];
    return result;
}

#pragma mark - Permission

- (BOOL)checkMicrophonePermission {
    /**
     Returns one of three statuses:
     Recording permission has been granted (AVAudioSessionRecordPermissionGranted).
     Recording permission has been denied (AVAudioSessionRecordPermissionDenied).
     denied需要使用下面自定义的UIAlertController引导用户进入settings开启麦克风权限
     Recording permission has not been requested (AVAudioSessionRecordPermissionUndetermined).
     not been requested系统会异步弹出系统级别的UIAlertController让用户直接赋予权限
     用户尚未赋予权限的情况下，录音信息为空。
     */
    switch ([AVAudioSession sharedInstance].recordPermission) {
        case AVAudioSessionRecordPermissionGranted: return YES;
        case AVAudioSessionRecordPermissionDenied: {
            UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
            if (vc) {
                UIAlertController *alert =   [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"您可以在系统设置中打开录音所需的麦克风权限" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction actionWithTitle:@"前往设置" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
#pragma clang diagnostic pop
                }];
                UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:ok];
                [alert addAction:cancel];
                [vc presentViewController:alert animated:YES completion:nil];
            }
        } return NO;
        case AVAudioSessionRecordPermissionUndetermined:
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
            return NO;
    }
}

#pragma mark - Life cycle

- (void)start {
    if (![self checkMicrophonePermission]) {
        typeof(self) __autoreleasing autoreleasingSelf = self;
        [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
        [autoreleasingSelf didAbort];
        return;
    }
    //超时限制：录制时长不能超过1分钟（1分钟AMR音频文件约为100KB）
    if ([self initSession] && [_audioRecorder recordForDuration:kWSRecordingToneMaxRecordDuration]) {
        _hasValidRecord = YES;
        [self didStart];
    } else [self abort];
}

- (void)stop {
    _hasValidRecord = _audioRecorder.currentTime > 1;
    [_audioRecorder stop];
}

- (void)abort {
    _hasValidRecord = NO;
    [_audioRecorder stop];
}

- (void)resume {
    [_audioRecorder record];
    [self didResume];
}

- (void)pause {
    [_audioRecorder pause];
    [self didPause];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    typeof(self) __autoreleasing autoreleasingSelf = self;
    [autoreleasingSelf abort];
    [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
    [autoreleasingSelf didAbort];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    /**
     注意：与AVAudioPlayer不同，当-[AVAudioRecorder stop]这个方法调用并停止成功后(或者超时结束后)会在主线程异步回调这个方法。
     所以一定要在这个方法中取data，否则会导致所取的data不完整，从而在使用data时发生空指针异常。
     也就是说，如果直接在-[WSRecordingToneChat stop]执行以下逻辑时录音文件有一部分尚未录入完成，还不能做持久化存储。
     */
    typeof(self) __autoreleasing autoreleasingSelf = self;
    NSData *audioData = nil;
    if (flag && _hasValidRecord) {
        audioData = EncodeWAVEToAMR([NSData dataWithContentsOfURL:recorder.url], 1, 16);
        [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
        [autoreleasingSelf didStopWithData:audioData];
    } else {
        [[WSToneManager defaultManager] adjustStackWithEndedTone:autoreleasingSelf];
        [autoreleasingSelf didAbort];
    }
}

@end
