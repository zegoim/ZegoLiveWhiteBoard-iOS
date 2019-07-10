//
//  ZegoUser+NSCopying.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/27.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUser+NSCopying.h"

@implementation ZegoUser (NSCopying)

- (id)copyWithZone:(NSZone *)zone {
    ZegoUser *user = [[ZegoUser alloc] init];
    user.userId = self.userId;
    user.userName = self.userName;
    
    return user;
}

@end
