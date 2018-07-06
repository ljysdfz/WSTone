//
//  WSPlayingTone.h
//  TestIOS
//
//  Created by 黎靖阳 on 1/2/17.
//  Copyright © 2017 Telecom. All rights reserved.
//

#import "WSTone.h"
#import "WSTone+Private.h"

NS_ASSUME_NONNULL_BEGIN

/**
 播放型tone
 
 ###播放的四个基本动作分别有以下几个注意点：
 1. Abort 由于可被<WSToneManager>直接引用执行中断操作，所以其只包含纯粹的终止逻辑，这样可以减小粒度，方便剪裁重用。
 2. Stop 由于不被外部引用，所以其还包含了通知<WSToneManager>和回调delegate的外部逻辑
 3. Pause & Resume 由于不需要被<WSToneManager>感知，所以只增加了回调delegate的外部逻辑
 */
@interface WSPlayingTone : WSTone <AVAudioPlayerDelegate>

/**
 @brief 播放型Tone指定类构造方法
 @param soundData 需要播放的声音文件的二进制数据，可支持的格式包括但不限于amr,mp3,wav,caf,m4a,aif,au,snd,aac。
 @param isAmbitious 是否主动型。见<WSTone>类说明
 @param isRepeated 是否重复播放。
 @param vibrateOnRing 是否振动。
 @param resumeAfterInterruption 是否在被系统高优先级音频事件中断结束后重启tone。
 @param toneDelegate <WSPlayingToneDelegate>协议的委托对象，用于接收tone的生命周期消息。
 @return 当前对象实例
 */
- (instancetype)initWithSoundData:(NSData *)soundData
                      isAmbitious:(BOOL)isAmbitious
                       isRepeated:(BOOL)isRepeated
                    vibrateOnRing:(BOOL)vibrateOnRing
          resumeAfterInterruption:(BOOL)resumeAfterInterruption
                     toneDelegate:(nullable id<WSPlayingToneDelegate>)toneDelegate NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
