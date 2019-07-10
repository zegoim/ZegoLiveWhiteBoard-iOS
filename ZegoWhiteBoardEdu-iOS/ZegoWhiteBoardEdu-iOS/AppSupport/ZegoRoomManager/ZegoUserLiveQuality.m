//
//  ZegoUserLiveQuality.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUserLiveQuality-Protected.h"

@implementation ZegoUserLiveQuality

+ (instancetype)liveQualityWithPublishQuality:(ZegoApiPublishQuality)quality {
    ZegoUserLiveQuality *instance = [[self alloc] init];
    instance.videoFPS = quality.fps;
    instance.videoEncFPS = quality.vencFps;
    instance.videoKbps = quality.kbps;
    instance.audioKbps = quality.akbps;
    instance.rtt = quality.rtt;
    instance.packetLoss = (float)quality.pktLostRate * 100 / 255;
    instance.netQuality = quality.quality;
    instance.audioDelay = 0;
    
    return instance;
}

+ (instancetype)liveQualityWithPlayQuality:(ZegoApiPlayQuality)quality {
    ZegoUserLiveQuality *instance = [[self alloc] init];
    instance.videoWidth = quality.width;
    instance.videoHeight = quality.height;
    instance.videoDecFPS = quality.vdecFps;
    instance.videoRndFPS = quality.vrndFps;
    instance.videoFPS = quality.fps;
    instance.videoKbps = quality.kbps;
    instance.audioKbps = quality.akbps;
    instance.rtt = quality.rtt;
    instance.packetLoss = (float)quality.pktLostRate * 100 / 255;
    instance.netQuality = quality.quality;
    instance.audioDelay = quality.delay;
    
    return instance;
}

@end
