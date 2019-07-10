//
//  ZegoChatroomInfo.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/19.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoRoomInfo.h"
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines-IM.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoomApiDefines-IM.h>
#endif

@implementation ZegoRoomInfo

+ (instancetype)roomInfoWithRoomID:(NSString *)roomID
                             owner:(ZegoUser *)owner {
    return [self roomInfoWithRoomID:roomID roomName:nil owner:owner];
}

+ (instancetype)roomInfoWithRoomID:(NSString *)roomID
                          roomName:(nullable NSString *)roomName
                             owner:(ZegoUser *)owner {
    ZegoRoomInfo *instance = [[ZegoRoomInfo alloc] init];
    instance.roomID = roomID;
    instance.roomName = roomName?:@"";
    instance.owner = owner;
    
    return instance;
}

+ (instancetype)roomInfoWithRoomID:(NSString *)roomID
                          roomName:(nullable NSString *)roomName
                           ownerID:(NSString *)ownerID
                         ownerName:(NSString *)ownerName; {
    ZegoUser *user = [[ZegoUser alloc] init];
    user.userId = ownerID;
    user.userName = ownerName;
    
    return [self roomInfoWithRoomID:roomID roomName:roomName owner:user];
}

@end
