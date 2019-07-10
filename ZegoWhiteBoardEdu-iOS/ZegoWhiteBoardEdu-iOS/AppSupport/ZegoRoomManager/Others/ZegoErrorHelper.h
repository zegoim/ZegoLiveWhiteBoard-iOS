//
//  ZegoErrorHelper.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/13.
//  Copyright © 2019 zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain ZegoErrorDomain;

@interface ZegoErrorHelper : NSObject

+ (NSError *)errorWithCode:(int)errorCode description:(NSString *)desc domain:(NSErrorDomain)domain;

@end

NS_ASSUME_NONNULL_END
