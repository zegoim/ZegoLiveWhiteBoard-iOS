//
//  ZegoUserLiveQuality.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ZegoUserLiveQuality : NSObject

/** 视频流宽度(像素) */
@property (assign, nonatomic) double videoWidth;
/** 视频流高度(像素) */
@property (assign, nonatomic) double videoHeight;
/** 视频帧率(网络发送/接收) */
@property (assign, nonatomic) double videoFPS;
/** 视频帧率(编码) */
@property (assign, nonatomic) double videoEncFPS;
/** 视频帧率(解码) */
@property (assign, nonatomic) double videoDecFPS;
/** 视频帧率(接收渲染) */
@property (assign, nonatomic) double videoRndFPS;
/** 视频码率(kb/s 网络发送/接收) */
@property (assign, nonatomic) double videoKbps;
/** 音频码率(kb/s 网络发送/接收) */
@property (assign, nonatomic) double audioKbps;
/** 延时(ms) */
@property (assign, nonatomic) int rtt;
/** 丢包率(0.0~100.0) */
@property (assign, nonatomic) float packetLoss;
/** 质量(0~3) */
@property (assign, nonatomic) int netQuality;
/** 语音延迟(ms) */
@property (assign, nonatomic) int audioDelay;

@end

NS_ASSUME_NONNULL_END
