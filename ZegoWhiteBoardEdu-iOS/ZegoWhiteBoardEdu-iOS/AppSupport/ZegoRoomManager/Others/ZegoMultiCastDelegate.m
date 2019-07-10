//
//  ZegoMultiCastDelegate.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/25.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoMultiCastDelegate.h"

@interface ZegoMultiCastDelegate ()

@property (strong, nonatomic) NSHashTable *delegates;

@end

@implementation ZegoMultiCastDelegate

+ (instancetype)delegate {
    ZegoMultiCastDelegate *instance = [ZegoMultiCastDelegate alloc];
    instance.delegates = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    return instance;
}

- (void)addDelegate:(id)delegate {
    [_delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
    [_delegates removeObject:delegate];
}

- (void)removeAll {
    [_delegates removeAllObjects];
}

- (void)doNothing {}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    for (id delegate in _delegates) {
        NSMethodSignature *signature = [delegate methodSignatureForSelector:aSelector];
        if (signature) {
            return signature;
        }
    }
    
    return [self.class instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSArray *allDelegates = self.allDelegates;
    
    for (id delegate in allDelegates) {
        if ([delegate respondsToSelector:anInvocation.selector]) {
            [anInvocation invokeWithTarget:delegate];
        }
    }
}

- (NSArray *)allDelegates {
    return _delegates.allObjects;
}

@end
