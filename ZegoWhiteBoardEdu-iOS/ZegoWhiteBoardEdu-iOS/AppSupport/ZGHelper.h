//
//  ZGHelper.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <ZegoLiveRoom/ZegoLiveRoom.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGHelper : NSObject

@property (class, strong, nonatomic, readonly) ZegoUser *user;

+ (NSString *)getDeviceUUID;

@end

NS_ASSUME_NONNULL_END
