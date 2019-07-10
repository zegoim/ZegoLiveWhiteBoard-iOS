//
//  ZegoUserLiveInfo.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/22.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUserLiveInfo-Protected.h"

@implementation ZegoUserLiveInfo

- (ZegoUserLiveStatus)status {
    if (self.streamStatus == kZegoUserLiveStatusLive) {
        return self.liveStatus;
    }
    
    return self.streamStatus;
}

- (void)setStreamStatus:(ZegoUserLiveStatus)streamStatus {
    if (_streamStatus == streamStatus) {
        return;
    }
    
    _streamStatus = streamStatus;
    
    if (streamStatus == kZegoUserLiveStatusLive) {
        self.liveStatus = kZegoUserLiveStatusLive;
    }
}

@end
