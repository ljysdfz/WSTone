//
//  WSMuteDetector.h
//  MicroVideo
//
//  Created by 黎靖阳 on 12/27/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

///取得静音状态后的回调方法
typedef void(^HandleMuteBlock)(BOOL isMute);

#import <Foundation/Foundation.h>

/**
 此类用于线程安全地检测当前静音键状态。
 
 ###Algorithm:
 1. Res文件夹下存放着一份100ms长度数量级的测试音频文件detection.aiff
 2. 播放测试音频，并异步启动累加器
 3. 时长是有波动的。有声情况下，时长会衰减低至0.002s；静音情况下，时长会增加至0.001s
 4. 通过实验采样后按照第3条中对timer信号间隔和时长阀值的正确选取，即可区分有声和静音状态 -- 选取有声的最小值和静音的最大值之间的真空地带
 
 ###Samples:
 * (CGFloat) $1 = 0.0110000009            //有声
 * (CGFloat) $2 = 0.273000032             //有声
 * (CGFloat) $3 = 0.00300000003           //来回切换静音状态的有声下限
 * (CGFloat) $4 = 0.002                   //来回切换前后台有声下限
 * (CGFloat) $5 = 0                       //静音下限
 * (CGFloat) $6 = 0.00100000005           //静音上限
 
 @bug 这个算法必须根据不同项目在实际机型上前后台切换实验取kThreshold的值，否则有不精准的风险。
 */
@interface WSMuteDetector : NSObject

/**
 @brief 检测当前静音键状态
 @param completion 取得静音状态后的回调方法，主线程回调
 */
+ (void)detectMuteSwitchWithCompletion:(void(^)(BOOL isMute))completion;
@end
