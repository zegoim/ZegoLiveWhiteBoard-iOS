//
//  ZegoStream+Equalable.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/22.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoStream+Equalable.h"

@implementation ZegoStream (Equalable)

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }
    return [self.streamID isEqualToString:[(ZegoStream *)object streamID]];
}

- (NSUInteger)hash {
    return self.streamID.hash;
}

@end
