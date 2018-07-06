//
//  WSTone.h
//  MicroVideo
//
//  Created by 黎靖阳 on 12/27/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WSTone;

NS_ASSUME_NONNULL_BEGIN

///播放型Tone生命周期委托协议
@protocol WSPlayingToneDelegate <NSObject>
@optional

///----------------------------------
/// @name Playing callbacks
///----------------------------------

/**
 @brief tone第一次启动播放后回调
 @param tone 启动播放的tone
 */
- (void)didStartPlayingTone:(WSTone *)tone;
/**
 @brief tone正常播放结束后回调，此时tone的context将被回收
 @param tone 停止播放的tone
 */
- (void)didStopPlayingTone:(WSTone *)tone;
/**
 @brief tone因为被打断而暂停。仅限于非紧迫型tone回调。（参考<[WSTone resumeAfterInterruption]>属性）
 @param tone 暂停播放的tone
 */
- (void)didPausePlayingTone:(WSTone *)tone;
/**
 @brief tone曾经暂停，之后恢复播放时回调。仅限于非紧迫型tone回调。（参考<[WSTone resumeAfterInterruption]>属性）
 @param tone 重新开始播放的tone
 */
- (void)didResumePlayingTone:(WSTone *)tone;
/**
 @brief tone播放夭折，将启动播放却因为优先级冲突或系统限制等因素遭到<WSToneManager>拒绝
 @param tone 播放夭折的tone
 */
- (void)didAbortPlayingTone:(WSTone *)tone;

@end

///录制型Tone生命周期委托协议
@protocol WSRecordingToneDelegate <NSObject>
@optional

///----------------------------------
/// @name Recording callbacks
///----------------------------------

/**
 @brief tone第一次启动录音后回调
 @param tone 启动的tone
 */
- (void)didStartRecordingTone:(WSTone *)tone;
/**
 @brief tone正常停止录音后回调，此时tone的context将被回收
 @param tone 停止录音的tone
 @param data 交付委托方的录音数据，默认为amr类型
 */
- (void)didStopRecordingTone:(WSTone *)tone withData:(nullable NSData *)data;
/**
 @brief tone因为被打断而暂停。仅限于非紧迫型tone回调。（参考<[WSTone resumeAfterInterruption]>属性）
 @param tone 暂停录音的tone
 */
- (void)didPauseRecordingTone:(WSTone *)tone;
/**
 @brief tone曾经暂停，之后恢复录音时回调。仅限于非紧迫型tone回调。（参考<[WSTone resumeAfterInterruption]>属性）
 @param tone 重新开始录音的tone
 */
- (void)didResumeRecordingTone:(WSTone *)tone;
/**
 @brief tone录音被中断而停止，将启动录制却因为优先级冲突或系统限制等因素遭到<WSToneManager>拒绝
 @param tone 录音夭折的tone
 */
- (void)didAbortRecordingTone:(WSTone *)tone;

@end

/**
 Tone类族的抽象父类
 
 1. 外部普通app的声音基本不影响本app声音。当其他音乐正在后台播放时，来了我们的声音会压低或停止（根据对方的类型）对方的音乐；本app播放结束后再恢复被中断的外部app。其他声音在前台播放时，我们的声音在后台启动一般会被压低少许声音。
 2. 如电话／闹钟等的系统app的高优先级声音会打断本app声音 ；结束后会根据被打断声音的不同类型来决定是否重启。（参考<resumeAfterInterruption>属性）
 3. 正在播放声音时来了新的内部声音，如果新来的声音优先级低或相等则只是振动(如果已经在振动，例如静音情况下的Incoming tone，则直接退出)；如果优先级高则停止前一个声音，播放完后根据被中断声音的重启策略决定是否重启。（参考<resumeAfterInterruption>属性）
 4. 切换声道（包括插拔耳机）会自动选择最后切换到的声道（输入／输出）声音。
 5. 录音时系统不允许振动，所以此时启动播放的声音如果优先级不比录音事件高，则无法收到振动；否则将停止当前录音并播放高优先级声音。
 6. 支持后台播放和后台录音。
 7. tone的主动型与被动型区别：1）主动型tone无视系统静音键，任何情况都会播放声音；当被动型遇到静音情况时，会变为振动。2）主动型tone优先级比被动型tone高。
 8. 音量默认为当前系统音量值的100%并跟随系统音量变化。
 */
@interface WSTone : NSObject

///----------------------------------
/// @name Class Methods
///----------------------------------

/**
 @brief 播放型Tone指定类构造方法
 @param soundURL 需要播放的声音文件的 ***本地URL***，可支持的格式包括但不限于amr,mp3,wav,caf,m4a,aif,au,snd,aac。
 @param isAmbitious 是否主动型。见<WSTone>类说明。
 @param isRepeated 是否重复播放。
 @param vibrateOnRing 播放声音时是否振动。
 @param resumeAfterInterruption 是否在被系统高优先级音频事件中断结束后重启tone。
 @param toneDelegate <WSPlayingToneDelegate>协议的委托对象，用于接收tone的生命周期消息。
 @return 当前对象实例。
 @warning 不可以使用网络远程URL构造<soundURL>。
 */
+ (instancetype)playingToneWithSoundURL:(NSURL *)soundURL
                            isAmbitious:(BOOL)isAmbitious
                             isRepeated:(BOOL)isRepeated
                          vibrateOnRing:(BOOL)vibrateOnRing
                resumeAfterInterruption:(BOOL)resumeAfterInterruption
                           toneDelegate:(nullable id<WSPlayingToneDelegate>)toneDelegate;
/**
 播放型Tone指定类构造方法
 @param soundData 需要播放的声音的二进制数据，可支持的格式包括但不限于amr,mp3,wav,caf,m4a,aif,au,snd,aac。
 @param isAmbitious 是否主动型。见<WSTone>类说明。
 @param isRepeated 是否重复播放。
 @param vibrateOnRing 是否振动。
 @param resumeAfterInterruption 是否在被系统高优先级音频事件中断结束后重启tone。
 @param toneDelegate <WSPlayingToneDelegate>协议的委托对象，用于接收tone的生命周期消息。
 @return 当前对象实例
 */
+ (instancetype)playingToneWithSoundData:(NSData *)soundData
                             isAmbitious:(BOOL)isAmbitious
                              isRepeated:(BOOL)isRepeated
                           vibrateOnRing:(BOOL)vibrateOnRing
                 resumeAfterInterruption:(BOOL)resumeAfterInterruption
                            toneDelegate:(nullable id<WSPlayingToneDelegate>)toneDelegate;
/**
 录制型Tone指定类构造方法
 
 录制型Tone有如下特征：
 
 1. 最终将生成AMR类型的音频数据。
 2. 主动型。见<WSTone>类说明。
 3. 不重复录制。
 4. 不振动不播放声音。
 5. 在被系统高优先级音频事件中断结束后不重启
 @param toneDelegate <WSRecordingToneDelegate>协议的委托对象，用于接收tone的生命周期消息
 @return 当前对象实例
 */
+ (instancetype)recordingToneWithToneDelegate:(nullable id<WSRecordingToneDelegate>)toneDelegate;

@end

NS_ASSUME_NONNULL_END
