//
//  ZegoErrorHelper+RoomManager.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/13.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoErrorHelper.h"
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-error-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-error-oc.h>
#endif

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain ZegoRoomErrorDomain;
extern NSErrorDomain ZegoRoomTempBrokeErrorDomain;
extern NSErrorDomain ZegoRoomKickErrorDomain;
extern NSErrorDomain ZegoRoomDisconnectErrorDomain;
extern NSErrorDomain ZegoPublishErrorDomain;
extern NSErrorDomain ZegoPlayErrorDomain;
extern NSErrorDomain ZegoLiveEventErrorDomain;
extern NSErrorDomain ZegoSendCustomCmdErrorDomain;

extern const int ZegoRoomParamErrorCode;
extern const int ZegoRoomLoginTimeoutErrorCode;

@interface ZegoErrorHelper (RoomManager)

+ (NSError *)roomErrorWithCode:(int)errorCode;
+ (NSError *)roomTempBrokeErrorWithCode:(int)errorCode;
+ (NSError *)roomKickoutErrorWithCode:(int)errorCode;
+ (NSError *)roomDisconnectErrorWithCode:(int)errorCode;
+ (NSError *)publishErrorWithCode:(int)errorCode;
+ (NSError *)playErrorWithCode:(int)errorCode;
+ (NSError *)liveEventTempBrokeError;
+ (NSError *)sendCustomCmdErrorWithCode:(int)errorCode;

@end

NS_ASSUME_NONNULL_END
