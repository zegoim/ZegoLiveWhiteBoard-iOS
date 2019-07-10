//
//  ZegoDefines.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/13.
//  Copyright © 2019 zego. All rights reserved.
//

#ifndef ZegoDefines_h
#define ZegoDefines_h

#define ZegoChatroomErrorIndex -1

#define Weakify( x ) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__weak __typeof__(x) __weak_##x##__ = x; \
_Pragma("clang diagnostic pop")

#define Strongify( x ) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong __typeof__(x) x = __weak_##x##__; \
_Pragma("clang diagnostic pop") \
if (!self) {return;}

#endif /* ZegoDefines_h */
