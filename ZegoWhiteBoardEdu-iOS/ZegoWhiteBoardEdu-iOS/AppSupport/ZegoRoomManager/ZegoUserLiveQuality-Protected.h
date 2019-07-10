//
//  ZegoUserLiveQuality-Protected.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/9.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUserLiveQuality.h"
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-defines-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#endif


@interface ZegoUserLiveQuality ()

+ (instancetype)liveQualityWithPublishQuality:(ZegoApiPublishQuality)quality;
+ (instancetype)liveQualityWithPlayQuality:(ZegoApiPlayQuality)quality;

@end
