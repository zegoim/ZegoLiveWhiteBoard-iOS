//
//  ZegoMultiCastDelegate.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/2/25.
//  Copyright © 2019 zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 多播代理转发器
 代理方法在本线程调用
 */
@interface ZegoMultiCastDelegate <__covariant DelegateType> : NSProxy

@property (strong, nonatomic, readonly) NSArray<DelegateType>* allDelegates;

+ (instancetype)delegate;

- (void)addDelegate:(DelegateType)delegate;
- (void)removeDelegate:(DelegateType)delegate;
- (void)removeAll;

@end

NS_ASSUME_NONNULL_END
