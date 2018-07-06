//
//  WSToneUtil.m
//  TestIOS
//
//  Created by 黎靖阳 on 1/2/17.
//  Copyright © 2017 Telecom. All rights reserved.
//

#import "WSToneUtil.h"
#import <AVFoundation/AVFoundation.h>

@implementation WSToneUtil

+ (void)runTaskInMainThread:(dispatch_block_t)block {
    if (!block) return;
    if ([NSThread isMainThread]) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

+ (void)vibrateOnce {AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);}

+ (BOOL)isAMRAudioData:(NSData *)soundData {
    ///AMR音频文件头
    const char *kHeaderOfAMRFile = "#!AMR\n";
    return !strncmp([soundData bytes], kHeaderOfAMRFile, strlen(kHeaderOfAMRFile));
}

+ (BOOL)isEarpods:(NSString *)portType {
    return [portType isEqualToString:AVAudioSessionPortHeadphones] || [portType isEqualToString:AVAudioSessionPortBluetoothA2DP];
}

@end
