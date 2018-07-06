//
//  Mp3Recorder.h
//  BloodSugar
//
//  Created by PeterPan on 14-3-24.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AMRRecorderDelegate <NSObject>
- (void)failRecord;
- (void)beginConvert;
- (void)endConvertWithData:(NSData *)voiceData;
- (void)updatePeakPowerForChanne:(double)peakPowerForChannel;

@end

@interface AMRRecorder : NSObject
@property (nonatomic, weak) id<AMRRecorderDelegate> delegate;

- (id)initWithDelegate:(id<AMRRecorderDelegate>)delegate;
- (void)startRecord;
- (void)stopRecord;
- (void)cancelRecord;

@end
