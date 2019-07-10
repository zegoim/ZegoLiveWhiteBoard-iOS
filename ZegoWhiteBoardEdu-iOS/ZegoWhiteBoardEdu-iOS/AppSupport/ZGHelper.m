//
//  ZGHelper.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGHelper.h"
#import <UIKit/UIKit.h>


NSString* kZGUserIDKey = @"user_id";
static ZegoUser *_user = nil;

@implementation ZGHelper

+ (NSUserDefaults *)myUserDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.WhiteBoardEdu"];
}

+ (ZegoUser *)user {
    if (!_user) {
        _user = [ZegoUser new];
        _user.userId = [self userID];
        _user.userName = UIDevice.currentDevice.name;
    }
    
    return _user;
}

+ (NSString *)userID {
    NSUserDefaults *ud = [self myUserDefaults];
    NSString *userID = [ud stringForKey:kZGUserIDKey];
    if (userID.length > 0) {
        return userID;
    }
    else {
        srand((unsigned)time(0));
        userID = [NSString stringWithFormat:@"%u", (unsigned)rand()];
        
        [ud setObject:userID forKey:kZGUserIDKey];
        [ud synchronize];
        
        return userID;
    }
}

+ (NSString *)getDeviceUUID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

@end
