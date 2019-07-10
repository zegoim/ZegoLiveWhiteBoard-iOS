//
//  ZGApiManager.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGApiManager.h"
#import "ZGKeyCenter.h"

static ZegoLiveRoomApi *s_apiInstance = nil;

@implementation ZGApiManager

+ (ZegoLiveRoomApi*)api {
    if (!s_apiInstance) {
        s_apiInstance = [[ZegoLiveRoomApi alloc] initWithAppID:ZGKeyCenter.appID appSignature:ZGKeyCenter.appSign];
    }
    
    return s_apiInstance;
}

+ (void)releaseApi {
    s_apiInstance = nil;
}

@end

