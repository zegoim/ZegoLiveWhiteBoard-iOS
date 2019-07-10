//
//  ZegoChatroomInfo.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/19.
//  Copyright © 2019 zego. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZegoUser;

NS_ASSUME_NONNULL_BEGIN

@interface ZegoRoomInfo : NSObject

@property (copy, nonatomic) NSString *roomID;
@property (copy, nonatomic) NSString *roomName;
@property (strong, nonatomic) ZegoUser *owner;

+ (instancetype)roomInfoWithRoomID:(NSString *)roomID
                             owner:(ZegoUser *)owner;

+ (instancetype)roomInfoWithRoomID:(NSString *)roomID
                          roomName:(nullable NSString *)roomName
                             owner:(ZegoUser *)owner;

+ (instancetype)roomInfoWithRoomID:(NSString *)roomID
                          roomName:(nullable NSString *)roomName
                           ownerID:(NSString *)ownerID
                         ownerName:(NSString *)ownerName;

@end

NS_ASSUME_NONNULL_END
