//
//  ZegoWhiteBoardViewController.h
//  ZegoWhiteBoardEdu-iOS
//
//  Created by Sky on 2019/5/28.
//  Copyright © 2019 zego. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZegoWhiteBoardViewController : UIViewController

@property (copy, nonatomic) NSString *roomID;
@property (copy, nonatomic) NSString *roomUUID;
@property (copy, nonatomic) NSString *roomToken;
@property (copy, nonatomic) NSString *teacherUserID;

@end

NS_ASSUME_NONNULL_END
