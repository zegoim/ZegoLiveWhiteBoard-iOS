//
//  ZegoErrorHelper+RoomManager.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/13.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoErrorHelper+RoomManager.h"

NSErrorDomain ZegoRoomErrorDomain = @"ZegoRoomErrorDomain";
NSErrorDomain ZegoRoomTempBrokeErrorDomain = @"ZegoRoomTempBrokeErrorDomain";
NSErrorDomain ZegoRoomKickErrorDomain = @"ZegoRoomKickErrorDomain";
NSErrorDomain ZegoRoomDisconnectErrorDomain = @"ZegoRoomDisconnectErrorDomain";
NSErrorDomain ZegoPublishErrorDomain = @"ZegoPublishErrorDomain";
NSErrorDomain ZegoPlayErrorDomain = @"ZegoPlayErrorDomain";
NSErrorDomain ZegoLiveEventErrorDomain = @"ZegoLiveEventErrorDomain";
NSErrorDomain ZegoSendCustomCmdErrorDomain = @"ZegoSendCustomCmdErrorDomain";

const int ZegoRoomParamErrorCode = -0x11112;
const int ZegoRoomLoginTimeoutErrorCode = -0x11111;

@implementation ZegoErrorHelper (RoomManager)

+ (NSError *)roomErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        case ZegoRoomLoginTimeoutErrorCode: errorMsg = @"登录重试超时"; break;
        case ZegoRoomParamErrorCode: errorMsg = @"参数非法"; break;
        case kLiveRoomThirdTokenAuthError: errorMsg = @"Token 错误"; break;
        case kConfigServerCouldntConnectError: errorMsg = @"无法连接配置服务器，请检查网络是否正常"; break;
        case kConfigServerTimeoutError: errorMsg = @"连接配置服务器超时，请检查网络是否正常"; break;
        case kLiveRoomCouldntConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kLiveRoomTimeoutError: errorMsg = @"连接房间服务器超时，请检查网络是否正常"; break;
        case kLiveRoomAddUserError: errorMsg = @"房间服务器报错，添加用户失败，请联系 ZEGO 技术支持解决（设置了观众无法创建房间后，以观众身份创建房间）"; break;
        case kRoomDecodeSignError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        case kRoomConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kRoomDoLoginReqError: errorMsg = @"发送 login 到房间服务器失败，请检查网络是否正常"; break;
        case kRoomTimeoutError: errorMsg = @"登录房间服务器超时，请检查网络是否正常"; break;
        case kRoomHbTimeoutError: errorMsg = @"房间服务器心跳超时，请检查网络是否正常"; break;
        case kRoomStartConnectError: errorMsg = @"与房间服务器连接失败，请联系 ZEGO 技术支持解决"; break;
        case kRoomStatusRspError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        default: errorMsg = @"undefined error"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoRoomErrorDomain];
}

+ (NSError *)roomTempBrokeErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        default: errorMsg = @"connect temp broke"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoRoomErrorDomain];
}

+ (NSError *)roomKickoutErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        case kRoomMultipleLoginKickoutError: errorMsg = @"账户多点登录被踢出"; break;
        case kRoomManualKickoutError: errorMsg = @"被主动踢出"; break;
        case kLiveRoomSessionError:
        case kRoomSessionErrorKickoutError: errorMsg = @"房间会话错误被踢出"; break;
        default: errorMsg = @"undefined error"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoRoomKickErrorDomain];
}

+ (NSError *)roomDisconnectErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        case kLiveRoomAddUserError: errorMsg = @"房间服务器报错，添加用户失败，请联系 ZEGO 技术支持解决"; break;
        case kRoomConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kRoomTimeoutError: errorMsg = @"登录房间服务器超时，请检查网络是否正常"; break;
        case kRoomHbTimeoutError: errorMsg = @"房间服务器心跳超时，请检查网络是否正常"; break;
        case kRoomStatusRspError:
        case kRoomDecodeSignError:
        case kRoomLoginSameCreateUserError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        default: errorMsg = @"undefined error"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoRoomDisconnectErrorDomain];
}

+ (NSError *)publishErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        case kNotLoginError: errorMsg = @"未登录房间，请检查是否已成功登录房间"; break;
        case kPublishBadNameError: errorMsg = @"重复的推流流名"; break;
        case kFormatUrlError: errorMsg = @"URL 格式错误，请联系 ZEGO 技术支持解决"; break;
        case kNetworkDnsResolveError: errorMsg = @"DNS 解析失败，请确认startPublishing 的 flag 是否为0/2，正确的情况下再检查网络是否正常"; break;
        case kDeniedDisableSwitchLineError: errorMsg = @"禁止切换线路重推，请调用推流接口重新推流"; break;
        case kEngineNoPublishDataError: errorMsg = @"推流无法推出数据，请检查网络是否正常"; break;
        case kEngineConnectServerError: errorMsg = @"连接 RTMP 服务器失败，请检查网络是否正常"; break;
        case kEngineServerDisconnectError: errorMsg = @"RTMP 服务器断开连接，请检查网络是否正常"; break;
        case kEngineRtpConnectServerError: errorMsg = @"连接 RTP 服务器失败，请检查网络是否正常"; break;
        case kEngineRtpHelloTimeoutError: errorMsg = @"连接 RTP 服务器超时，请检查网络是否正常"; break;
        case kEngineRtpCreateSessionTimeoutError: errorMsg = @"与 RTP 服务器创建 session 超时，请检查网络是否正常"; break;
        case kEngineRtpTimeoutError: errorMsg = @"RTP 超时，请检查网络是否正常"; break;
        case kPlayStreamNotExistError: errorMsg = @"流不存在，请检查拉取的流是否已推流成功"; break;
        case kMediaServerForbidError: errorMsg = @"ZEGO 后台禁止推流，请联系 ZEGO 技术支持解决"; break;
        case kMediaServerPublishBadNameError: errorMsg = @"推流使用重复的流名"; break;
        case kConfigMediaNetworkNoUrlError: errorMsg = @"媒体服务无 URL，请联系 ZEGO 技术支持解决"; break;
        case kConfigServerCouldntConnectError: errorMsg = @"无法连接配置服务器，请检查网络是否正常"; break;
        case kConfigServerTimeoutError: errorMsg = @"连接配置服务器超时，请检查网络是否正常"; break;
        case kDispatchServerCouldntConnectError: errorMsg = @"无法连接调度服务器，请检查网络是否正常"; break;
        case kDispatchServerTimeoutError: errorMsg = @"连接调度服务器超时，请检查网络是否正常"; break;
        case kLiveRoomRequestParamError: errorMsg = @"房间参数错误，请联系 ZEGO 技术支持解决"; break;
        case kLiveRoomHBTimeoutError: errorMsg = @"房间心跳超时，请检查网络是否正常"; break;
        case kLiveRoomNoPushServerAddrError: errorMsg = @"未找到推流服务地址，请联系 ZEGO 技术支持解决"; break;
        case kLiveRoomCouldntConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kLiveRoomTimeoutError: errorMsg = @"连接房间服务器超时，请检查网络是否正常"; break;
        case kLiveRoomRoomAuthError: errorMsg = @"房间服务器报错，鉴权失败，请联系 ZEGO 技术支持解决"; break;
        case kLiveRoomNotLoginError: errorMsg = @"房间服务器报错，未登录房间，请检查是否已成功登录房间"; break;
        case kLiveRoomAddUserError: errorMsg = @"房间服务器报错，添加用户失败，请联系 ZEGO 技术支持解决"; break;
        case kLiveRoomNetBrokenTimeoutError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        case kLiveRoomPublishBadNameError: errorMsg = @"房间服务器报错，重复的推流流名"; break;
        case kRoomConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kRoomTimeoutError: errorMsg = @"登录房间服务器超时，请检查网络是否正常"; break;
        case kRoomHbTimeoutError: errorMsg = @"房间服务器心跳超时，请检查网络是否正常"; break;
        case kRoomDecodeSignError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        case kRoomLoginCreateUserError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        case kRoomStatusRspError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        case kRoomMultipleLoginKickoutError: errorMsg = @"重复登录房间被踢，请检查是否已登录房间"; break;
        default: errorMsg = @"undefined error"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoPublishErrorDomain];
}

+ (NSError *)playErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        case kNetworkDnsResolveError: errorMsg = @"DNS 解析失败，请检查网络是否正常"; break;
        case kEngineNoPlayDataError: errorMsg = @"拉流无法拉到数据，请检查拉的流是否存在或者网络是否正常"; break;
        case kEngineConnectServerError: errorMsg = @"连接 RTMP 服务器失败，请检查网络是否正常"; break;
        case kEngineRtmpHandshakeError: errorMsg = @"RTMP 服务连接握手失败，请联系 ZEGO 技术支持解决"; break;
        case kEngineRtmpAppConnectError: errorMsg = @"连接 RTMP 服务器失败，请联系 ZEGO 技术支持解决"; break;
        case kEngineServerDisconnectError: errorMsg = @"RTMP 服务器断开连接，请检查网络是否正常"; break;
        case kEngineRtpConnectServerError: errorMsg = @"连接 RTP 服务器失败，请检查网络是否正常"; break;
        case kEngineRtpHelloTimeoutError: errorMsg = @"连接 RTP 服务器超时，请检查网络是否正常"; break;
        case kEngineRtpCreateSessionTimeoutError: errorMsg = @"与 RTP 服务器创建 session 超时，请检查网络是否正常"; break;
        case kEngineRtpTimeoutError: errorMsg = @"RTP 超时，请检查网络是否正常"; break;
        case kEngineHttpFlvServerDisconnectError: errorMsg = @"http flv 服务器断开连接，请检查网络是否正常"; break;
        case kPlayStreamNotExistError: errorMsg = @"拉的流不存在，请检查拉取的流是否已推流成功"; break;
        case kMediaServerForbidError: errorMsg = @"ZEGO 后台禁止推流，请联系 ZEGO 技术支持解决"; break;
        case kConfigServerCouldntConnectError: errorMsg = @"无法连接配置服务器，请检查网络是否正常"; break;
        case kConfigServerTimeoutError: errorMsg = @"连接配置服务器超时，请检查网络是否正常"; break;
        case kDispatchStreamNotExistError: errorMsg = @"调度服务器报错，流不存在，请检查拉取的流是否已推流成功"; break;
        case kLiveRoomHBTimeoutError: errorMsg = @"房间心跳超时，请检查网络是否正常"; break;
        case kLiveRoomCouldntConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kLiveRoomTimeoutError: errorMsg = @"连接房间服务器超时，请检查网络是否正常"; break;
        case kLiveRoomNotLoginError: errorMsg = @"房间服务器报错，未登录房间，请检查是否已成功登录房间"; break;
        case kLiveRoomSessionError: errorMsg = @"房间服务器报错，Session错误，请联系 ZEGO 技术支持解决"; break;
        case kLiveRoomAddUserError: errorMsg = @"房间服务器报错，添加用户失败，请联系 ZEGO 技术支持解决"; break;
        case kRoomConnectError: errorMsg = @"无法连接房间服务器，请检查网络是否正常"; break;
        case kRoomTimeoutError: errorMsg = @"登录房间服务器超时，请检查网络是否正常"; break;
        case kRoomHbTimeoutError: errorMsg = @"房间服务器心跳超时,请检查网络是否正常"; break;
        case kRoomDecodeSignError: errorMsg = @"房间服务器报错，请联系 ZEGO 技术支持解决"; break;
        case kRoomMultipleLoginKickoutError: errorMsg = @"重复登录房间被踢，请检查是否已登录房间"; break;
        default: errorMsg = @"undefined error"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoPlayErrorDomain];
}

+ (NSError *)liveEventTempBrokeError {
    NSString *errorMsg = @"流临时中断，SDK将自动重试。";
    
    return [self errorWithCode:7 description:errorMsg domain:ZegoLiveEventErrorDomain];
}

+ (NSError *)sendCustomCmdErrorWithCode:(int)errorCode {
    NSString *errorMsg = nil;
    switch (errorCode) {
        case kNotLoginError: errorMsg = @"not login";
        case ZegoRoomParamErrorCode: errorMsg = @"param invalid"; break;
        default: errorMsg = @"network error"; break;
    }
    
    return [self errorWithCode:errorCode description:errorMsg domain:ZegoSendCustomCmdErrorDomain];
}

@end
