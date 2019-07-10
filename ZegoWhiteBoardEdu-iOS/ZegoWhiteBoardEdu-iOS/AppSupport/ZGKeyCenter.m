//
//  ZGKeyCenter.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/10.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGKeyCenter.h"

@implementation ZGKeyCenter

+ (unsigned int)appID {
    return <#AppID#>;
}

+ (NSData *)appSign {
    Byte signkey[] = <#AppSign#>;
    NSData* sign = [NSData dataWithBytes:signkey length:32];
    
    return sign;
}

@end
