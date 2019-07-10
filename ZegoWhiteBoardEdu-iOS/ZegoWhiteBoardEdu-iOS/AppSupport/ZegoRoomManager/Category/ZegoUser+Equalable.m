//
//  ZegoUser+Equalable.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/15.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUser+Equalable.h"

@implementation ZegoUser (Equalable)

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }
    return [self.userId isEqualToString:[(ZegoUser *)object userId]];
}

- (NSUInteger)hash {
    return self.userId.hash;
}

@end
