//
//  WSToneManager+Private.h
//  TestIOS
//
//  Created by 黎靖阳 on 12/29/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import "WSToneManager.h"
#import "WSTone.h"

@interface WSToneManager ()
///是否正在振动
@property (nonatomic) BOOL isRunningVibratingTone;
/**
 @brief 清除tone并重新调整任务栈
 @param tone 需要终止的tone
 */
- (void)adjustStackWithEndedTone:(WSTone *)tone;
@end
