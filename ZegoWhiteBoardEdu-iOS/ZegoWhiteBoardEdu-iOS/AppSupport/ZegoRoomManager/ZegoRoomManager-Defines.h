//
//  ZegoRoomManager-Defines.h
//  ZegoCapsuleClass
//
//  Created by Sky on 2019/4/19.
//  Copyright © 2019 zego. All rights reserved.
//

#ifndef ZegoRoomManager_Defines_h
#define ZegoRoomManager_Defines_h


/**
 房间登录状态

 - kZegoRoomLoginStatusLogout: 未登录
 - kZegoRoomLoginStatusStartLogin: 开始登录请求
 - kZegoRoomLoginStatusLogin: 已登录
 - kZegoRoomLoginStatusTempBroken: 暂时断开房间连接
 */
typedef NS_ENUM(NSInteger, ZegoRoomLoginStatus) {
    kZegoRoomLoginStatusLogout,
    kZegoRoomLoginStatusStartLogin,
    kZegoRoomLoginStatusLogin,
    kZegoRoomLoginStatusTempBroken,
};

/**
 房间登录事件

 - kZegoRoomLoginEventLogin: 开始登录请求
 - kZegoRoomLoginEventLoginSuccess: 登录请求成功
 - kZegoRoomLoginEventLoginFailed: 登录请求失败
 - kZegoRoomLoginEventLogout: 退出登录
 - kZegoRoomLoginEventTempBroke: 房间连接暂时断开
 - kZegoRoomLoginEventReconnect: 房间连接恢复
 - kZegoRoomLoginEventDisconnect: 重连超时，停止重连断开房间连接
 - kZegoRoomLoginEventKickOut: 被踢出房间，断开房间连接
 */
typedef NS_ENUM(NSInteger, ZegoRoomLoginEvent) {
    kZegoRoomLoginEventLogin,
    kZegoRoomLoginEventLoginSuccess,
    kZegoRoomLoginEventLoginFailed,
    kZegoRoomLoginEventLogout,
    kZegoRoomLoginEventTempBroke,
    kZegoRoomLoginEventReconnect,
    kZegoRoomLoginEventDisconnect,
    kZegoRoomLoginEventKickOut,
};

/**
 房间重连终止原因

 - kZegoRoomReconnectStopReasonParam: 入参不合法
 - kZegoRoomReconnectStopReasonLogout: 手动调用leaveRoom终止重连
 - kZegoRoomReconnectStopReasonKickout: 被服务器踢出终止重连
 - kZegoRoomReconnectStopReasonTimeout: 重连timeout
 */
typedef NS_ENUM(NSInteger, ZegoRoomReconnectStopReason) {
    kZegoRoomReconnectStopReasonParam,
    kZegoRoomReconnectStopReasonLogout,
    kZegoRoomReconnectStopReasonKickout,
    kZegoRoomReconnectStopReasonTimeout,
};

/**
 房间成员直播连接状态

 - kZegoUserLiveStatusWaitConnect: 未连接直播
 - kZegoUserLiveStatusConnecting: 正在请求直播连接
 - kZegoUserLiveStatusLive: 直播已连接
 */
typedef NS_ENUM(NSInteger, ZegoUserLiveStatus) {
    kZegoUserLiveStatusWaitConnect,
    kZegoUserLiveStatusConnecting,
    kZegoUserLiveStatusLive,
};


#endif /* ZegoRoomManager_Defines_h */
