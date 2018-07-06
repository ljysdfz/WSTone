//
//  WSToneMgr.m
//  MicroVideo
//
//  Created by 黎靖阳 on 12/10/16.
//  Copyright © 2016 Telecom. All rights reserved.
//

#import "WSToneManager.h"
#import "WSToneManager+Private.h"
#import "WSTone.h"
#import "WSTone+Private.h"
#import "WSToneUtil.h"

//单例
static WSToneManager *_toneManager;

@implementation WSToneManager {
    ///正在播放的tone，与<_suspendedTone>组成任务栈
    WSTone *_runningTone;
    /**
     当前等待播放的Tone。
     当两个tone发生冲突时（即一个新tone进入时，旧tone正在播放），
     <WSToneManager>根据冲突处理原则，若旧tone是一个优先级较低的非imperative tone，
     则将其放入<_suspendingTone>。
     当<_runningTone>播放结束时，仍未有其他tone进入，
     则当前<_suspendingTone>会作为新的<_runningTone>启动播放。若有其他非imperative tone进入，
     根据冲突处理原则，<WSToneManager>会将当前<_suspendingTone>抛弃。
     */
    WSTone *_suspendedTone;
}

#pragma mark - Initializers

///----------------------------------
/// @name Initializers
///----------------------------------

+ (instancetype)defaultManager {return [self new];}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _toneManager = [super allocWithZone:zone];
    });
    return _toneManager;
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _toneManager = [super init];
        // if media services are reset, we need to rebuild our audio chain
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMediaServerLost)
                                                     name:AVAudioSessionMediaServicesWereLostNotification
                                                   object:[AVAudioSession sharedInstance]];
    });
    return _toneManager;
}

#pragma mark - Tone methods

///----------------------------------
/// @name Public Methods
///----------------------------------

- (void)executeTone:(WSTone *)tone {
    //tone是nil或者非WSTone类型对象
    BOOL toneIsNilOrNotATone = ![tone isKindOfClass:[WSTone class]];
    //tone是抽象父类WSTone的直接对象
    BOOL toneIsAPlainMember = [tone isMemberOfClass:[WSTone class]];
    if (toneIsNilOrNotATone || toneIsAPlainMember) return;
    
    [WSToneUtil runTaskInMainThread:^{
        //当前没有tone在播放
        //----------------------------
        if (!_runningTone) {
            //那就开播吧！
            _runningTone = tone;
            [_runningTone start];
            return;
        }
        //当前有tone在播放
        //----------------------------
        //tone已经处于任务栈中则直接退出
        if (tone==_runningTone || tone==_suspendedTone) return;
        //开始执行优先级冲突算法
        if (tone.isAmbitious > _runningTone.isAmbitious) {
            //新来的是中央首长，位高权重，老干部赶紧退位让贤
            if (_runningTone.resumeAfterInterruption) {
                //老勾践等不到收复河山的一天被废弃，因为新干部来当勾践了，世上只能有一个勾践
                [_suspendedTone abort];
                [_suspendedTone didAbort];
                //综合型老干部替换老勾践，卧薪尝胆，待时机成熟，三千越甲可吞吴
                [_runningTone pause];
                _suspendedTone = _runningTone;
            } else {
                //紧迫型老干部无意东山再起，从此归隐南山
                [_runningTone abort];
                [_runningTone didAbort];
            }
            //更新tone后开始播放
            _runningTone = tone;
            [_runningTone start];
        } else {
            //因为级别不够，胎死腹中
            [tone didAbort];
            if (![WSToneManager defaultManager].isRunningVibratingTone) [WSToneUtil vibrateOnce];
        }
    }];
}

- (void)terminateTone:(WSTone *)tone {
    //tone是nil或者非WSTone类型对象
    BOOL toneIsNilOrNotATone = ![tone isKindOfClass:[WSTone class]];
    //tone是抽象父类WSTone的直接对象
    BOOL toneIsAPlainMember = [tone isMemberOfClass:[WSTone class]];
    if (toneIsNilOrNotATone || toneIsAPlainMember) return;
    [WSToneUtil runTaskInMainThread:^{
        //tone不在任务栈中则直接退出
        if (!(tone==_runningTone || tone==_suspendedTone)) return;
        [tone stop];
    }];
}

- (void)adjustStackWithEndedTone:(WSTone *)tone {
    if (!tone) return;
    [WSToneUtil runTaskInMainThread:^{
        if (tone == _runningTone) {
            if (_suspendedTone) {
                _runningTone  = _suspendedTone;
                _suspendedTone = nil;
                [_runningTone resume];
            } else {
                _runningTone = nil;
            }
        } else if (tone == _suspendedTone) {
            _suspendedTone = nil;
        }
    }];
}

#pragma mark - Notification

///Media Server宕机的回调方法
- (void)handleMediaServerLost {
    //虽然已知在主线程执行的回调
    //为了日后替换线程队列时方便所以还是使用队列block
    [WSToneUtil runTaskInMainThread:^{
        //清理所有任务栈内的tone
        if (_suspendedTone) [self terminateTone:_suspendedTone];
        if (_runningTone) [self terminateTone:_runningTone];
    }];
}

#pragma mark - Accessor

///----------------------------------
/// @name Accessor
///----------------------------------

- (BOOL)isRunningVibratingTone {
    return _runningTone.isVibrating;
}

@end
