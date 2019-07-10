//
//  ZegoRoomManager.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/22.
//  Copyright © 2019 zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Publisher.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Player.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#endif
#import "ZegoRoomManager-Defines.h"
#import "ZegoRoomInfo.h"
#import "ZegoErrorHelper+RoomManager.h"
#import "ZegoUserLiveInfo.h"


@class ZegoRoomManager;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ZegoLoginRoomCallback)(NSError * _Nullable error);
typedef void(^ZegoSendCustomCmdCallback)(NSError * _Nullable error);


@protocol ZegoRoomManagerDelegate <NSObject>
@optional
//登录事件&状态回调
- (void)roomManager:(ZegoRoomManager *)manager
 didLoginEventOccur:(ZegoRoomLoginEvent)event
        loginStatus:(ZegoRoomLoginStatus)status
              error:(nullable NSError *)error;

//以下几种情况将终止自动重新登录
- (void)roomManager:(ZegoRoomManager *)manager didAutoReconnectStop:(ZegoRoomReconnectStopReason)reason;

//推拉流用户更新
- (void)roomManager:(ZegoRoomManager *)manager didLiveUserJoin:(ZegoUser *)user;
- (void)roomManager:(ZegoRoomManager *)manager didLiveUserLeave:(ZegoUser *)user;

//Custom Command
- (void)roomManager:(ZegoRoomManager *)manager didRecvCustomCommand:(ZegoUser *)fromUser content:(NSString*)content;

@end


@protocol ZegoRoomManagerLiveStatusDelegate <NSObject>
@optional
- (void)roomManager:(ZegoRoomManager *)manager
didLiveStatusChange:(ZegoUserLiveStatus)liveStatus
               user:(ZegoUser *)user
              error:(nullable NSError *)error;

- (void)roomManager:(ZegoRoomManager *)manager didUserGetFirstFrame:(ZegoUser *)user size:(CGSize)size;

- (void)roomManager:(ZegoRoomManager *)manager didUserVideoFrameChange:(ZegoUser *)user size:(CGSize)size;

- (void)roomManager:(ZegoRoomManager *)manager didRenderRemoteUserVideoFrame:(ZegoUser *)user;

- (void)roomManager:(ZegoRoomManager *)manager
  didGetSoundLevels:(NSDictionary<ZegoUser*,NSNumber*>*)soundLevels;

- (void)roomManager:(ZegoRoomManager *)manager
 didExtraInfoUpdate:(nullable NSString *)extraInfo
               user:(ZegoUser *)user;

- (void)roomManager:(ZegoRoomManager *)manager
didUserLiveQualityUpdate:(ZegoUserLiveQuality *)quality
               user:(ZegoUser *)user;

@end


@protocol ZegoRoomManagerIDGenerateDelegate <NSObject>
- (NSString *)genLiveIDWithUser:(ZegoUser *)user;
@end


@interface ZegoRoomManager : NSObject <ZegoLivePlayerDelegate, ZegoLiveEventDelegate>

@property (assign, nonatomic, readonly) BOOL onlyAudio;
@property (strong, nonatomic, nullable, readonly) ZegoRoomInfo *roomInfo;
@property (strong, nonatomic, readonly) ZegoUser *userInfo;

@property (assign, nonatomic, readonly) BOOL isPreview;
@property (assign, nonatomic, readonly) BOOL isLogin;
@property (assign, nonatomic, readonly) BOOL isDisconnect;
@property (assign, nonatomic, readonly) BOOL isSelfLive;
@property (assign, nonatomic, readonly) ZegoRoomLoginStatus loginStatus;

@property (strong, nonatomic, readonly) NSArray<ZegoUser*>* liveUsers;

@property (assign, nonatomic) BOOL autoReconnectRoom;//断线自动重连房间
@property (assign, nonatomic) NSTimeInterval reconnectInterval;//房间断线重连、推拉流失败重试操作间隔,s,1.0
@property (assign, nonatomic) NSUInteger reconnectTimeout;//房间断线重连超时时间,s，默认0，不会超时
@property (assign, nonatomic) BOOL soundLevelMonitor;//开启声浪监听
@property (assign, nonatomic) NSTimeInterval soundLevelMonitorCycle;//声浪监听时间,s，0.1-3.0，默认1.0

+ (instancetype)managerWithApi:(ZegoLiveRoomApi *)api onlyAudio:(BOOL)onlyAudio;

- (void)addDelegate:(id <ZegoRoomManagerDelegate>)delegate;
- (void)removeDelegate:(id <ZegoRoomManagerDelegate>)delegate;
- (void)addLiveStatusDelegate:(id <ZegoRoomManagerLiveStatusDelegate>)delegate;
- (void)removeLiveStatusDelegate:(id <ZegoRoomManagerLiveStatusDelegate>)delegate;
- (void)setIDGenerateDelegate:(nullable id <ZegoRoomManagerIDGenerateDelegate>)delegate;

- (void)joinRoom:(ZegoRoomInfo *)roomInfo user:(ZegoUser *)userInfo completion:(nullable ZegoLoginRoomCallback)completion;
- (void)leaveRoom;

- (void)startLive;
- (void)stopLive;
- (void)startPreview;
- (void)stopPreview;

- (void)setLiveExtraInfo:(NSString *)extraInfo;
- (void)setVolume:(NSUInteger)volume forUser:(ZegoUser *)user;
- (void)setLiveVideoView:(nullable ZEGOView *)view viewMode:(ZegoVideoViewMode)mode forUser:(nullable ZegoUser *)user;//onlyAudio 无效，user传空就是设置本地预览

- (void)sendCustomCommand:(NSString *)content
               memberList:(NSArray<ZegoUser*> *)memberList
               completion:(nullable ZegoSendCustomCmdCallback)completion;

- (nullable ZegoUserLiveInfo *)liveInfoForUser:(ZegoUser *)user;

@end


NS_ASSUME_NONNULL_END
