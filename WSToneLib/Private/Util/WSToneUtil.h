//
//  WSToneUtil.h
//  TestIOS
//
//  Created by 黎靖阳 on 1/2/17.
//  Copyright © 2017 Telecom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 tone的工具类
 */
@interface WSToneUtil : NSObject

/**
 @brief 在主线程执行任务。若receiver已经在主线程，则同步执行；否则异步派发。
 @param block 要执行的任务块
 */
+ (void)runTaskInMainThread:(dispatch_block_t)block;
///振动一次
+ (void)vibrateOnce;
/**
 @brief 判断soundData是否AMR格式的音频数据
 @param soundData 需要鉴别的音频数据
 */
+ (BOOL)isAMRAudioData:(NSData *)soundData;
/**
 @brief 判断portType是否耳机类型（有线耳机／蓝牙耳机）
 @param portType 需要鉴别的音频端口设备类型
 */
+ (BOOL)isEarpods:(NSString *)portType;

@end

NS_ASSUME_NONNULL_END
