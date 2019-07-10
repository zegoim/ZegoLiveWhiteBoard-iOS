//
//  ZegoUserLiveInfo.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/22.
//  Copyright © 2019 zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#endif
#import "ZegoRoomManager-Defines.h"
#import "ZegoUserLiveQuality.h"

@class ZegoStream;


NS_ASSUME_NONNULL_BEGIN

@interface ZegoUserLiveInfo : NSObject

@property (assign, nonatomic) ZegoUserLiveStatus status;

@property (assign, nonatomic) BOOL firstFrame;
@property (assign, nonatomic) float soundLevel;
@property (copy, nonatomic, nullable) NSString *extraInfo;
@property (strong, nonatomic, nullable) ZegoUserLiveQuality *liveQuality;

@property (nonatomic, weak, nullable) ZEGOView *videoView;
@property (assign, nonatomic) ZegoVideoViewMode viewMode;

@end

NS_ASSUME_NONNULL_END
