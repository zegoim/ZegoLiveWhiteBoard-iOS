//
//  NSString+ZG_MD5.m
//  ZegoCapsuleClass
//
//  Created by Sky on 2019/4/22.
//  Copyright © 2019 zego. All rights reserved.
//

#import "NSString+ZG_MD5.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (ZG_MD5)

- (NSString *)zg_md5 {
    if (!self) {
        return nil;
    }
    
    const char *cStr = self.UTF8String;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    NSMutableString *md5Str = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        [md5Str appendFormat:@"%02x", result[i]];
    }
    
    return md5Str;
}

@end
