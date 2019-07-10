//
//  ZegoUser+NSCoding.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/18.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoUser+NSCoding.h"

@implementation ZegoUser (NSCoding)

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.userId = [aDecoder decodeObjectForKey:@"userId"];
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
}

@end
