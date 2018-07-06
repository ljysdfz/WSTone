//
//  WSToneMgr.h
//  MicroVideo
//
//  Created by 黎靖阳 on 12/10/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSTone.h"

NS_ASSUME_NONNULL_BEGIN

/**
 此类用于线程安全地执行全局音频任务，包括 震动 & 响铃
*/
@interface WSToneManager : NSObject

///----------------------------------
/// @name Public Methods
///----------------------------------

///单例方法
+ (instancetype)defaultManager;
/**
 @brief 异步执行tone(包含录音和播放声音、振动)。请监听<WSToneDelegate>回调获取tone的生命周期变化。
 @param tone 要播放的tone
 @warning 以下情况会导致方法直接返回：
 
 1. tone为nil
 2. tone非<WSTone>类型对象
 3. tone为使用WSTone的init方法直接初始化生成的对象(正确做法请使用<WSTone>的类构造器)
 4. tone已经处于任务栈中
 */
- (void)executeTone:(WSTone *)tone;

/**
 @brief 异步终止指定的tone。请监听<WSToneDelegate>回调获取tone的生命周期变化。
 @param tone 要终止的tone
 @warning 以下情况会导致方法直接返回：
 
 1. tone为nil
 2. tone非<WSTone>类型对象
 3. tone为使用WSTone的init方法直接初始化生成的对象(正确做法请使用<WSTone>的类构造器)
 4. tone不在任务栈中
 */
- (void)terminateTone:(WSTone *)tone;

@end

NS_ASSUME_NONNULL_END
