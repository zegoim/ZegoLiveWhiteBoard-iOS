//
//  ZegoUser+Valid.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/15.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUser+Valid.h"

@implementation ZegoUser (Valid)

- (BOOL)isValid {
    return self.userId.length > 0 && self.userName.length > 0;
}

@end
