//
//  WSRecordingTone.h
//  TestIOS
//
//  Created by 黎靖阳 on 1/2/17.
//  Copyright © 2017 Telecom. All rights reserved.
//

#import "WSTone.h"
#import "WSTone+Private.h"

FOUNDATION_EXTERN NSTimeInterval const kWSRecordingToneMaxRecordDuration;

NS_ASSUME_NONNULL_BEGIN

/**
 录制型tone
 */
@interface WSRecordingTone : WSTone <AVAudioRecorderDelegate>

/**
 指定构造方法
 @param toneDelegate <WSRecordingToneDelegate>协议的委托对象，用于接收tone的生命周期消息
 @return 当前对象实例
 */
- (instancetype)initWithToneDelegate:(nullable id<WSRecordingToneDelegate>)toneDelegate NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
