//
//  ZegoReplayViewController.h
//  ZegoWhiteBoardEdu-iOS
//
//  Created by Sky on 2019/5/30.
//  Copyright © 2019 zego. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZegoReplayViewController : UIViewController

@property (copy, nonatomic) NSString *roomUUID;
@property (copy, nonatomic) NSString *videoURL;
@property (assign, nonatomic) NSTimeInterval createTime;

@end

NS_ASSUME_NONNULL_END
