//
//  WSTone+Private.h
//  TestIOS
//
//  Created by 黎靖阳 on 12/28/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WSTone.h"

NS_ASSUME_NONNULL_BEGIN

@interface WSTone()

#pragma mark - Extension Propertiess

///----------------------------------
/// @name Extension Properties
///----------------------------------

///是否主动型。见<WSTone>类说明。
@property (nonatomic) BOOL isAmbitious;
///该属性表示当前tone是否可以在被系统音频事件打断时pause并在中断结束时resume。
///YES代表当前tone为综合型；NO代表当前tone为紧迫型。
@property (nonatomic) BOOL resumeAfterInterruption;
///当前的tone播放声音时是否伴随振动
@property (nonatomic) BOOL vibrateOnRing;
///是否正在振动
@property (nonatomic) BOOL isVibrating;

#pragma mark - Extension Methods

///----------------------------------
/// @name Extension Methods
///----------------------------------

///第一次启动播放。
- (void)start;
///正常停止播放。被用户手动停止或播放结束。调用后tone的context将被回收
- (void)stop;
///正在播放时暂停播放，未来可以通过<resume>重启。
- (void)pause;
///曾经<pause>，之后恢复播放。
- (void)resume;
///夭折。启动时因为而优先级冲突、系统禁止、播放模式限制等因素被<WSToneManager>拒绝播放。
- (void)abort;
///通知委托：tone已启动
- (void)didStart;
/**
 @brief 通知委托：tone已正常停止
 @param data 需要返回给调用方的音频数据
 */
- (void)didStopWithData:(nullable NSData *)data;
///通知委托：tone已被中断暂停
- (void)didPause;
///通知委托：tone已从中断暂停中恢复
- (void)didResume;
///通知委托：tone已夭折
- (void)didAbort;
///初始化session
- (BOOL)initSession;
///结束session
- (void)deinitSession;

@end

NS_ASSUME_NONNULL_END
