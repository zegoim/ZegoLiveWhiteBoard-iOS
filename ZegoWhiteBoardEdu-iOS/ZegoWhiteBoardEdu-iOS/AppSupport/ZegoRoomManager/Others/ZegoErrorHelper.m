//
//  ZegoErrorHelper.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/13.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoErrorHelper.h"

NSErrorDomain ZegoErrorDomain = @"ZegoErrorDomain";

@implementation ZegoErrorHelper

+ (NSError *)errorWithCode:(int)errorCode description:(NSString *)desc domain:(NSErrorDomain)domain {
    NSDictionary *userInfo = nil;
    if (desc) {
        userInfo = @{NSLocalizedFailureReasonErrorKey:desc};
    }
    
    return [NSError errorWithDomain:domain code:errorCode userInfo:userInfo];
}

@end
