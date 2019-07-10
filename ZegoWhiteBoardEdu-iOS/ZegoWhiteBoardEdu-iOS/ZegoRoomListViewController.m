//
//  ZegoRoomListViewController.m
//  ZegoWhiteBoardEdu-iOS
//
//  Created by Sky on 2019/5/28.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoRoomListViewController.h"
#import "ZegoWhiteBoardViewController.h"
#import "ZegoReplayViewController.h"

@interface ZegoRoomCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation ZegoRoomCell
@end


@interface ZegoRoomListViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *reconnectView;
@property (weak, nonatomic) IBOutlet UICollectionView *listView;

@property (assign, nonatomic) BOOL isRefreshing;
@property (strong, nonatomic) NSArray<NSDictionary*>* roomInfos;

@end

NSString *ZGRoomInfoRoomIDKey = @"roomId";
NSString *ZGRoomInfoRoomNameKey = @"roomName";
NSString *ZGRoomInfoCreateTimeKey = @"createAt";
NSString *ZGRoomInfoTeacherIDKey = @"teacherId";
NSString *ZGRoomInfoReplayURLKey = @"replayUrl";
NSString *ZGRoomWhiteScreenKey = @"whiteScreen";
NSString *ZGRoomInfoRoomTokenKey = @"roomToken";
NSString *ZGRoomInfoUUIDKey = @"uuid";

@implementation ZegoRoomListViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refresh];
}

#pragma mark - Actions

- (IBAction)refresh {
    if (self.isRefreshing) {
        return;
    }
    
    self.isRefreshing = YES;
    
    NSURL *url = [NSURL URLWithString:@"http://118.25.189.55:8092/class-room/rooms"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10;
    configuration.HTTPAdditionalHeaders = @{@"Content-Type":@"application/json"};
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    Weakify(self);
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            Strongify(self);
            
            self.isRefreshing = NO;
            
            if (error) {
                self.reconnectView.hidden = NO;
                return;
            }
            
            self.reconnectView.hidden = YES;
            self.roomInfos = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        });
    }];
    
    [task resume];
}

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.roomInfos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZegoRoomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ZegoRoomCell.class) forIndexPath:indexPath];
    
    
    NSDictionary *roomInfo = self.roomInfos[indexPath.item];
    NSString *teacherID = roomInfo[ZGRoomInfoTeacherIDKey];
    BOOL isReplayRoom = teacherID.length == 0;
    
    cell.titleLabel.text = [roomInfo[ZGRoomInfoRoomNameKey] stringByAppendingString:isReplayRoom ? @"(回放)":@""];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSDictionary *roomInfo = self.roomInfos[indexPath.item];
    
    NSString *teacherID = roomInfo[ZGRoomInfoTeacherIDKey];
    
    if (teacherID.length == 0) {
        ZegoReplayViewController *vc = [[ZegoReplayViewController alloc] init];
        vc.roomUUID = roomInfo[ZGRoomWhiteScreenKey][ZGRoomInfoUUIDKey];
        vc.createTime = [roomInfo[ZGRoomInfoCreateTimeKey] longValue] / 1000.f;
        vc.videoURL = roomInfo[ZGRoomInfoReplayURLKey];
        
        [self presentViewController:vc animated:YES completion:nil];
    }
    else {
        ZegoWhiteBoardViewController *vc = [[ZegoWhiteBoardViewController alloc] init];
        vc.roomID = roomInfo[ZGRoomInfoRoomIDKey];
        vc.roomToken = roomInfo[ZGRoomWhiteScreenKey][ZGRoomInfoRoomTokenKey];
        vc.roomUUID = roomInfo[ZGRoomWhiteScreenKey][ZGRoomInfoUUIDKey];
        vc.teacherUserID = teacherID;
        
        [self presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - Access

- (void)setIsRefreshing:(BOOL)isRefreshing {
    if (_isRefreshing == isRefreshing) {
        return;
    }
    
    _isRefreshing = isRefreshing;
    isRefreshing ? [ZegoHudManager showNetworkLoading]:[ZegoHudManager hideNetworkLoading];
}

- (void)setRoomInfos:(NSArray<NSDictionary *> *)roomInfos {
    _roomInfos = roomInfos;
    [self.listView reloadData];
}

@end
