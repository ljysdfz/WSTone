//
//  WSMuteDetector.m
//  MicroVideo
//
//  Created by 黎靖阳 on 12/27/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WSMuteDetector.h"
#include <AudioToolbox/AudioToolbox.h>

///播放测试音频的总时长
static CGFloat _soundDuration;
///测试静音状态时用于播放测试音频的timer
static dispatch_source_t _timer;
///处理最后得到的静音状态的回调函数，不用set而用array保证回调顺序FIFO
static NSMutableArray<HandleMuteBlock> *_muteHandlers;
///_timer信号的时间间隔
static const CGFloat kTimerInterval = 0.001;
//TODO: 测试阀值
///区分静音和有声的时长阀值
static const CGFloat kThreshold = 0.01;//0.002;

#pragma mark - Mute Switch Detection

static void startTimer(SystemSoundID soundID) {
    _soundDuration = 0.0;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(_timer, ^{_soundDuration += kTimerInterval;});
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, kTimerInterval*NSEC_PER_SEC, 0);
    dispatch_resume(_timer);
}

static void testSoundCompletionCallback(SystemSoundID ssID, void *clientData) {
    AudioServicesRemoveSystemSoundCompletion(ssID);
    dispatch_source_cancel(_timer);
    _timer = nil;
    /**
     Samples:
     (CGFloat) $1 = 0.0110000009            //有声
     (CGFloat) $2 = 0.273000032             //有声
     (CGFloat) $3 = 0.00300000003           //来回切换静音状态的有声下限
     (CGFloat) $4 = 0.002                   //来回切换前后台有声下限
     (CGFloat) $5 = 0                       //静音下限
     (CGFloat) $6 = 0.00100000005           //静音上限
     */
    
    if (_muteHandlers.count){
        BOOL isMute = _soundDuration < kThreshold;
        for (HandleMuteBlock block in _muteHandlers) {
            block(isMute);
        }
        [_muteHandlers removeAllObjects];
    }
}


@implementation WSMuteDetector
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _muteHandlers = [NSMutableArray arrayWithCapacity:1];
    });
}

+ (void)detectMuteSwitchWithCompletion:(void(^)(BOOL isMute))completion {
    dispatch_block_t block = ^{
#if TARGET_OS_IPHONE
        if (completion && ![_muteHandlers containsObject:completion]) {
            [_muteHandlers addObject:completion];
        } else return;
        //已有静音侦测任务在执行，则直接在其回调中享用共同结果即可
        if (_timer) return;
        // iOS 5+ doesn't allow mute switch detection using state length detection
        // So we need to play a blank 100ms file and detect the playback length
        CFURLRef		soundFileURL;
        SystemSoundID	soundID;
        // Get the URL to the sound file to play
        soundFileURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR ("detection"), CFSTR ("aiff"), NULL);
        // Create a system sound object representing the sound file
        AudioServicesCreateSystemSoundID(soundFileURL, &soundID);
        //如果没有自己当前线程的runloop传入，则回调方法会默认进入 main runloop，即在主线程回调
        //事实证明，回调方法运行的Runloop mode不需要设为kCFRunLoopCommonModes，在scrollView滑动时kCFRunLoopDefaultMode也能迅速响应来电
        AudioServicesAddSystemSoundCompletion(soundID, NULL, kCFRunLoopDefaultMode, testSoundCompletionCallback, NULL);
        AudioServicesPlaySystemSound(soundID);
        // Start the playback timer
        startTimer(soundID);
#else
        // The simulator doesn't support detection and can cause a crash so always return muted
        !completion ?: completion(YES);
#endif
    };
    //一定要在主线程执行，在异步线程及其runloop执行时
    //快速切换静音状态或者播放过程中切换状态很容易造成实际播放时状态紊乱
    if ([NSThread isMainThread]) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

@end
